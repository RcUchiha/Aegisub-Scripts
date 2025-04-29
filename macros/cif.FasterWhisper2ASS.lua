script_name = "FasterWhisper2ASS"
script_description = "Transcribe o traduce audios de líneas usando Faster-Whisper-XXL, configurable."
script_author = "CiferrC"
script_version = "1.0"
submenu = "_CiferrC's Scripts/"

local separador_ruta = package.config:sub(1,1)
local carpeta_temp = (os.getenv("TEMP") or os.getenv("TMPDIR") or "/tmp")
local archivo_configuracion = aegisub.decode_path("?user") .. separador_ruta .. "faster-whisper2ass.conf"

local idioma_map = {
    ["Japonés"] = "Japanese",
    ["Inglés"] = "English",
    ["Español"] = "Spanish",
    ["Francés"] = "French",
    ["Alemán"] = "German",
    ["Chino"] = "Chinese"
}

local idioma_codigos = {
    ["Japanese"] = "JA",
    ["English"] = "EN",
    ["Spanish"] = "ES",
    ["French"] = "FR",
    ["German"] = "DE",
    ["Chinese"] = "ZH"
}

local tarea_map = {
    ["Transcribir"] = "transcribe",
    ["Traducir"] = "translate"
}

local modelos = {"small", "medium", "large", "turbo"}

local function cargar_configuracion()
    local config = {ruta_fasterwhisper = "", ruta_ffmpeg = ""}
    local archivo = io.open(archivo_configuracion, "r")
    if archivo then
        config.ruta_fasterwhisper = archivo:read("*l") or ""
        config.ruta_ffmpeg = archivo:read("*l") or ""
        archivo:close()
    end
    return config
end

local function guardar_configuracion(config)
    local archivo = io.open(archivo_configuracion, "w")
    if archivo then
        archivo:write((config.ruta_fasterwhisper or "") .. "\n")
        archivo:write((config.ruta_ffmpeg or "") .. "\n")
        archivo:close()
    end
end

local function archivo_existe(ruta)
    if not ruta or ruta == "" then return false end
    local f = io.open(ruta, "r")
    if f then f:close() return true else return false end
end

local function normalizar_ruta(ruta)
    ruta = ruta:gsub("\\", "/")
    local partes = {}
    for parte in ruta:gmatch("[^/]+") do
        if parte == ".." then
            table.remove(partes)
        elseif parte ~= "." then
            table.insert(partes, parte)
        end
    end
    return table.concat(partes, separador_ruta)
end

local function obtener_numero_dialogo(subs, idx)
    local dialogo_index = 0
    for i = 1, idx do
        if subs[i].class == "dialogue" then
            dialogo_index = dialogo_index + 1
        end
    end
    return dialogo_index
end

local function borrar_archivo(ruta)
    if ruta and archivo_existe(ruta) then
        os.remove(ruta)
    end
end

local function pluralizar(palabra, cantidad)
    return cantidad == 1 and palabra or palabra .. "s"
end

local function configurar()
    local config = cargar_configuracion()
    local dialogo = {
        {class = "label", label = "Ruta de faster-whisper-xxl.exe:", x = 0, y = 0},
        {class = "edit", name = "ruta_fasterwhisper", value = config.ruta_fasterwhisper, x = 1, y = 0, width = 20},
        {class = "label", label = "Ruta de ffmpeg.exe:", x = 0, y = 1},
        {class = "edit", name = "ruta_ffmpeg", value = config.ruta_ffmpeg, x = 1, y = 1, width = 20}
    }

    local botones = {"Guardar", "FasterWhisper...", "FFmpeg...", "Cancelar"}

    while true do
        local presionado, res = aegisub.dialog.display(dialogo, botones)
        if presionado == "Guardar" then
            config.ruta_fasterwhisper = res.ruta_fasterwhisper
            config.ruta_ffmpeg = res.ruta_ffmpeg
            guardar_configuracion(config)
            aegisub.dialog.display({{class="label", label="Configuración guardada en:\n" .. archivo_configuracion}}, {"OK"})
            return
        elseif presionado == "FasterWhisper..." then
            local ruta = aegisub.dialog.open("Seleccionar faster-whisper-xxl.exe", "", "", "Ejecutable (*.exe)|*.exe", false, true)
            if ruta then dialogo[2].value = ruta end
        elseif presionado == "FFmpeg..." then
            local ruta = aegisub.dialog.open("Seleccionar ffmpeg.exe", "", "", "Ejecutable (*.exe)|*.exe", false, true)
            if ruta then dialogo[4].value = ruta end
        else
            return
        end
    end
end

local function transcribir_o_traducir(subs, sel)
    local config = cargar_configuracion()

    if not archivo_existe(config.ruta_fasterwhisper) or not archivo_existe(config.ruta_ffmpeg) then
        aegisub.dialog.display({{class="label", label="Configura primero las rutas de Faster-Whisper y FFmpeg."}}, {"OK"})
        configurar() -- <<==== Agregado aquí para abrir la GUI de configuración
        config = cargar_configuracion() -- Recargar config en caso de que haya sido actualizado
        if not archivo_existe(config.ruta_fasterwhisper) or not archivo_existe(config.ruta_ffmpeg) then
            aegisub.dialog.display({{class="label", label="Configuración incompleta. Operación cancelada."}}, {"OK"})
            return
        end
    end

    local opciones = {
        {class = "label", label = "Idioma de entrada:", x=0, y=0},
        {class = "dropdown", name = "idioma", items = {"Japonés", "Inglés", "Español", "Francés", "Alemán", "Chino"}, value="Japonés", x=1, y=0, width=2},
        {class = "label", label = "Modelo:", x=0, y=1},
        {class = "dropdown", name = "modelo", items = modelos, value="medium", x=1, y=1, width=2},
        {class = "label", label = "Tarea:", x=0, y=2},
        {class = "dropdown", name = "tarea", items = {"Transcribir", "Traducir"}, value="Transcribir", x=1, y=2, width=2}
    }

    local presionado, res = aegisub.dialog.display(opciones, {"Iniciar", "Cancelar"})
    if presionado ~= "Iniciar" then return end

    local idioma = idioma_map[res.idioma] or "Japanese"
    local modelo = res.modelo
    local tarea = tarea_map[res.tarea] or "transcribe"
    local texto_tarea = tarea == "transcribe" and "Transcripción" or "Traducción"

    local ruta_audio = aegisub.project_properties().audio_file
    local audio_normalizado = normalizar_ruta(ruta_audio)

    if not audio_normalizado or audio_normalizado == "?" then
        aegisub.dialog.display({{class="label", label="No hay audio o video cargado en el proyecto."}}, {"OK"})
        return
    end

    local exitos, fallos = 0, 0

    for i, idx in ipairs(sel) do
        local numero_dialogo = obtener_numero_dialogo(subs, idx)
        aegisub.log("\nLínea %d/%d:\n", i, #sel)

        local linea = subs[idx]
        local inicio = linea.start_time / 1000
        local fin = linea.end_time / 1000
        local duracion = fin - inicio
        local nombre_base = string.format("line_temp_audio_%03d", numero_dialogo)
        local wav_temp = string.format("%s%s%s.wav", carpeta_temp, separador_ruta, nombre_base)
        local ruta_txt = string.format("%s%s%s.txt", carpeta_temp, separador_ruta, nombre_base)

        local comando_extraer = string.format('cmd /C "%s -y -ss %f -t %f -i \"%s\" -c:a pcm_s16le \"%s"', config.ruta_ffmpeg, inicio, duracion, audio_normalizado, wav_temp)
        local handle = io.popen(comando_extraer, "r")
        if handle then handle:read("*a") handle:close() end

        if archivo_existe(wav_temp) then
            aegisub.log("✓ WAV creado\n")

            local comando_faster = string.format('cmd /C "\"%s\" \"%s\" --language %s --task %s --output_dir \"%s\" --output_format txt --model %s"', config.ruta_fasterwhisper, wav_temp, idioma, tarea, carpeta_temp, modelo)
            os.execute(comando_faster)

            if archivo_existe(ruta_txt) then
                local archivo = io.open(ruta_txt, "r", "utf-8")
                local transcripcion = archivo and archivo:read("*a") or ""
                if archivo then archivo:close() end

                if transcripcion and transcripcion:match("%S") then
                    transcripcion = transcripcion:gsub("%[.-%]%s*", ""):gsub("%s+$", "")
                    linea.text = (linea.text and linea.text ~= "") and (linea.text .. "{" .. transcripcion .. "}") or ("{" .. transcripcion .. "}")
                    
                    local efecto = linea.effect or ""
                    local codigo_idioma = idioma_codigos[idioma] or "JA"
                    if tarea == "transcribe" then
                        if not efecto:match("Transcripción " .. codigo_idioma) then
                            efecto = efecto .. "[Transcripción " .. codigo_idioma .. "]"
                        end
                    elseif tarea == "translate" then
                        if not efecto:match("Traducción EN") then
                            efecto = efecto .. "[Traducción EN]"
                        end
                    end
                    linea.effect = efecto
                    subs[idx] = linea
                    exitos = exitos + 1
                    aegisub.log("✓ " .. texto_tarea .. " insertada en línea " .. numero_dialogo .. "\n")
                else
                    fallos = fallos + 1
                    aegisub.log("✗ " .. texto_tarea .. " vacía o ilegible\n")
                end
            else
                fallos = fallos + 1
                aegisub.log("✗ No se generó " .. texto_tarea:lower() .. "\n")
            end
        else
            fallos = fallos + 1
            aegisub.log("✗ Error al crear WAV\n")
        end

        borrar_archivo(wav_temp)
        borrar_archivo(ruta_txt)
    end

    aegisub.log("\n※ Proceso completado: %d %s%s\n",
        exitos, pluralizar("éxito", exitos),
        fallos > 0 and string.format(", %d %s", fallos, pluralizar("fallo", fallos)) or "")
    return sel
end

aegisub.register_macro(submenu .. script_name .. "/Transcribir | Traducir", script_description, transcribir_o_traducir)
aegisub.register_macro(submenu .. script_name .. "/Configuración", "Configura las rutas de Faster-Whisper y FFmpeg.", configurar)
