script_name = "SAI Muxer"
script_description = "Agrega líneas de pistas con rutas para multiplexar con SAI."
script_author = "CiferrC"
script_version = "1.1.1"

local config_path = aegisub.decode_path("?user") .. "\\sai_config.conf"

-- Cargar configuración desde el archivo
local function cargar_configuracion()
    local config = { ruta_sai = "", ruta_mkvmerge = "" }
    local file = io.open(config_path, "r")
    if file then
        config.ruta_sai = file:read("*l") or ""
        config.ruta_mkvmerge = file:read("*l") or ""  -- Leer la ruta de mkvmerge
        file:close()
    end
    return config
end

-- Guardar configuración en el archivo
local function guardar_configuracion(config)
    local file = io.open(config_path, "w")
    file:write(config.ruta_sai .. "\n")
    file:write(config.ruta_mkvmerge .. "\n")  -- Guardar la ruta de mkvmerge
    file:close()

    -- Mostrar un mensaje indicando dónde se guardó la configuración
    aegisub.dialog.display(
        {{class="label", label="𝗖𝗼𝗻𝗳𝗶𝗴𝘂𝗿𝗮𝗰𝗶𝗼𝗻 𝗴𝘂𝗮𝗿𝗱𝗮𝗱𝗮 𝗲𝗻:\n" .. config_path}},
        {"OK"},
        {close="OK"}
    )
end

local function muxear(subs, sel)
    -- Cargar configuración
    local config = cargar_configuracion()
    if not config.ruta_sai or config.ruta_sai == "" then
        aegisub.log("Error: Ruta de sai.exe no configurada.\n")
        return
    end

    if not config.ruta_mkvmerge or config.ruta_mkvmerge == "" then
        aegisub.log("Error: Ruta de mkvmerge.exe no configurada.\n")
        return
    end

    -- Obtener el directorio y nombre del archivo de subtítulos
    local ruta_subtitulo = aegisub.decode_path("?script") .. "\\" .. aegisub.file_name()
    local dir_subtitulo = ruta_subtitulo:match("^(.*)\\")
    local nombre_subtitulo = ruta_subtitulo:match("\\([^\\]+)$")

    -- Validar si el archivo de subtítulos existe
    local archivo = io.open(ruta_subtitulo, "r")
    if not archivo then
        aegisub.log("Error: No se encontró el archivo de subtítulos: '%s'.\n", ruta_subtitulo)
        return
    end
    archivo:close()

    -- Preparar las rutas de los ejecutables para el PATH temporal
    local paths = {
        config.ruta_sai:match("^(.*)\\"),
        config.ruta_mkvmerge:match("^(.*)\\")
    }

    -- Construir el comando para ejecutar
    local comando = string.format(
        [[cmd /c "set PATH=%s;%%PATH%% && cd /d "%s" && "%s" mux %q"]],
        table.concat(paths, ";"), -- Concatenar las rutas con ';'
        dir_subtitulo,            -- Cambiar al directorio de los subtítulos
        config.ruta_sai,          -- Ejecutable de sai.exe
        nombre_subtitulo          -- Nombre del archivo de subtítulos
    )

    -- Log de depuración (mínimo pero informativo)
    aegisub.log("Ejecutando comando: %s\n", comando)

    -- Ejecutar el comando y capturar salida
    local handle = io.popen(comando, "r")
    if not handle then
        aegisub.log("Error: No se pudo abrir el proceso.\n")
        return
    end

    local salida = handle:read("*a") -- Leer la salida del comando
    local exit_code = handle:close() -- Cerrar el proceso y obtener el código de salida

    -- Verificar resultado del comando
    if exit_code == true or exit_code == 0 then
        aegisub.log("El comando se ejecutó correctamente.\n")
    else
        aegisub.log("Error: El comando falló con código: %s\nSalida del comando:\n%s", tostring(exit_code), salida)
    end
end

-- Definición del mapeo de idiomas
local idiomas = {
    en = "Inglés",
    es = "Español",
    fr = "Francés",
    de = "Alemán",
    ja = "Japonés",
    ko = "Coreano",
    zh = "Chino",
    it = "Italiano",
    ru = "Ruso",
    pt = "Portugués",
	ar = "Árabe",
    ["es-419"] = "Español Latino"  
}

-- Función para invertir el mapeo (nombre a clave)
local function invertir_mapeo(tabla)
    local invertido = {}
    for clave, valor in pairs(tabla) do
        invertido[valor] = clave
    end
    return invertido
end

local nombres_a_claves = invertir_mapeo(idiomas)

local function agregar_lineas(subs, sel)
    local extra_audio_count = 0
    local extra_subs_count = 0

	-- Función para construir la GUI
	local function construir_gui()
		-- Crear lista de idiomas para video (sin Español Latino)
		local items_idiomas_video = {}
		for clave, nombre in pairs(idiomas) do
			if clave ~= "es-419" then
				table.insert(items_idiomas_video, nombre)
			end
		end

		-- Crear lista de idiomas genérica (para audio, subtítulos, etc.)
		local items_idiomas = {}
		for _, nombre in pairs(idiomas) do
			table.insert(items_idiomas, nombre)
		end

		local dialog_config = {
			{ class = "label", label = "𝗣𝗶𝘀𝘁𝗮 𝗮 𝗮𝗴𝗿𝗲𝗴𝗮𝗿", x = 0, y = 0, width = 1, height = 1 },
			{ class = "label", label = "𝗜𝗱𝗶𝗼𝗺𝗮 𝗱𝗲 𝗽𝗶𝘀𝘁𝗮", x = 1, y = 0, width = 1, height = 1 },
			{ class = "label", label = "𝗡𝗼𝗺𝗯𝗿𝗲 𝗱𝗲 𝗽𝗶𝘀𝘁𝗮", x = 2, y = 0, width = 1, height = 1 },

			{ class = "checkbox", name = "video", label = "Video:", x = 0, y = 1 },
			{ class = "dropdown", name = "video_lang", items = items_idiomas_video, value = idiomas["ja"], x = 1, y = 1 },
			{ class = "edit", name = "video_name", value = "", hint = "Nombre de pista para video", x = 2, y = 1, width = 3 },

			{ class = "checkbox", name = "audio", label = "Audio:", x = 0, y = 2 },
			{ class = "dropdown", name = "audio_lang", items = items_idiomas, value = idiomas["ja"], x = 1, y = 2 },
			{ class = "edit", name = "audio_name", value = "", hint = "Nombre de pista para audio", x = 2, y = 2, width = 3 },

			{ class = "checkbox", name = "sub_lang", label = "Idioma de subs:", x = 0, y = 3 },
			{ class = "dropdown", name = "sub_lang_val", items = items_idiomas, value = idiomas["ja"], x = 1, y = 3, width = 1 },
			{ class = "edit", name = "sub_name", value = "", hint = "Nombre de pista para subtítulos", x = 2, y = 3, width = 3 },

			{ class = "checkbox", name = "fonts", label = "Fuentes", x = 0, y = 4 },
			{ class = "checkbox", name = "insert", label = "Inserts:", x = 0, y = 5 },
			{ class = "intedit", name = "insert_count", value = 1, min = 1, max = 10, x = 1, y = 5 },

			{ class = "label", label = "𝗡𝗼𝗺𝗯𝗿𝗲 𝗱𝗲𝗹 𝗮𝗿𝗰𝗵𝗶𝘃𝗼 𝗺𝘂𝗹𝘁𝗶𝗽𝗹𝗲𝘅𝗮𝗱𝗼:", x = 0, y = 6, width = 3 },
			{ class = "edit", name = "output_name", value = "", hint = "Nombre del archivo resultante", x = 0, y = 7, width = 5 }

		}

		-- Agregar opciones dinámicas para pistas extra de audio y subtítulos
		local y_pos = 7
		for i = 1, extra_audio_count do
			table.insert(dialog_config, { class = "label", label = "Extra Audio " .. i .. ":", x = 0, y = y_pos + i })
			table.insert(dialog_config, { class = "dropdown", name = "extra_audio_lang_" .. i, items = items_idiomas, value = idiomas["ja"], x = 1, y = y_pos + i })
			table.insert(dialog_config, { class = "edit", name = "extra_audio_name_" .. i, value = "", hint = "Nombre de pista para extra audio " .. i, x = 2, y = y_pos + i, width = 3 })
		end

		y_pos = y_pos + extra_audio_count
		for i = 1, extra_subs_count do
			table.insert(dialog_config, { class = "label", label = "Extra Subs " .. i .. ":", x = 0, y = y_pos + i })
			table.insert(dialog_config, { class = "dropdown", name = "extra_subs_lang_" .. i, items = items_idiomas, value = idiomas["ja"], x = 1, y = y_pos + i })
			table.insert(dialog_config, { class = "edit", name = "extra_subs_name_" .. i, value = "", hint = "Nombre de pista para extra subs " .. i, x = 2, y = y_pos + i, width = 3 })
		end

		return dialog_config
	end

    while true do
        local buttons = { "Agregar", "Cancelar", "Pista audio +1", "Pista subs +1" }
        local pressed, res = aegisub.dialog.display(construir_gui(), buttons)
        
        if pressed == "Cancelar" or pressed == false then
            return
        elseif pressed == "Agregar" then
            local lineas = {}

			if res.video and res.video_name ~= "" then
				local codigo_idioma = nombres_a_claves[res.video_lang]
				table.insert(lineas, string.format("{:video %s}[%s]", codigo_idioma, res.video_name))
			end

			if res.audio and res.audio_name ~= "" then
				local codigo_idioma = nombres_a_claves[res.audio_lang]
				table.insert(lineas, string.format("{:audio %s}[%s]", codigo_idioma, res.audio_name))
			end

			if res.sub_lang then
				local codigo_idioma = nombres_a_claves[res.sub_lang_val]
				local nombre_pista = res.sub_name -- Nombre de pista de subtítulos
				if nombre_pista and nombre_pista ~= "" then
					table.insert(lineas, string.format("{:subLang}[%s]%s", nombre_pista, codigo_idioma))
				else
					table.insert(lineas, string.format("{:subLang}%s", codigo_idioma))
				end
			end

			if res.fonts then
				if res.fonts_path and res.fonts_path ~= "" then
					table.insert(lineas, string.format("{:fonts}[%s]", res.fonts_path)) -- Incluir la ruta a la carpeta de las fuentes
				else
					table.insert(lineas, "{:fonts}Fonts") -- Si no hay ruta, usa el valor por defecto
				end
			end
			
			if res.insert then
				for i = 1, res.insert_count do
					local insert_path = res.insert_paths and res.insert_paths[i] or nil
					if insert_path and insert_path ~= "" then
						table.insert(lineas, string.format("{:insert}[%s]", insert_path))
					else
						table.insert(lineas, "{:insert}")
					end
				end
			end

			if res.output_name ~= "" then
				table.insert(lineas, string.format("{:outputName}%s", res.output_name))
			end

            -- Generar líneas para pistas extra de audio
            for i = 1, extra_audio_count do
                local lang = nombres_a_claves[res["extra_audio_lang_" .. i]]
                local name = res["extra_audio_name_" .. i]
                if name and name ~= "" then
                    table.insert(lineas, string.format("{:extraAudio %s}[%s]", lang, name))
                end
            end

            -- Generar líneas para pistas extra de subtítulos
            for i = 1, extra_subs_count do
                local lang = nombres_a_claves[res["extra_subs_lang_" .. i]]
                local name = res["extra_subs_name_" .. i]
                if name and name ~= "" then
                    table.insert(lineas, string.format("{:extraSubs %s}[%s]", lang, name))
                end
            end

			for i = #lineas, 1, -1 do
				local effect_value = ""  -- Por defecto, el campo effect estará vacío.
				
				-- Verificar si la línea es uno de los tipos que deben tener "Agregar ruta" en el campo effect
				if lineas[i]:match("{:video") or
				   lineas[i]:match("{:audio") or
				   lineas[i]:match("{:fonts") or
				   lineas[i]:match("{:extraAudio") or
				   lineas[i]:match("{:extraSubs") or
				   lineas[i]:match("{:insert") then
					effect_value = "[Agregar ruta]"
				end

				-- Insertar la línea con el valor adecuado para el campo effect
				subs.insert(1, {
					class = "dialogue",
					text = lineas[i],
					layer = 0,
					start_time = 0,
					end_time = 0,
					style = "Default",
					actor = "SAI",
					margin_l = 0,
					margin_r = 0,
					margin_t = 0,
					effect = effect_value,  -- Aquí se coloca el valor de effect
					comment = true
				})
			end
            aegisub.set_undo_point("Agregar líneas de pistas")
            return
        elseif pressed == "Pista audio +1" then
            extra_audio_count = extra_audio_count + 1
        elseif pressed == "Pista subs +1" then
            extra_subs_count = extra_subs_count + 1
        end
    end
end

local function agregar_chapters(subs, sel)
    -- Usar la tabla 'idiomas' directamente sin repetirla
    local items_idiomas = {}
    for clave, nombre in pairs(idiomas) do
        table.insert(items_idiomas, nombre)
    end

    local function construir_gui_chapters(chapter_count)
        local gui = {
            { class = "label", label = "𝗖𝗮𝗽𝗶𝘁𝘂𝗹𝗼", x = 0, y = 0, width = 1, height = 1 },
			{ class = "label", label = "𝗜𝗱𝗶𝗼𝗺𝗮 𝗱𝗲 𝗰𝗮𝗽.", x = 1, y = 0, width = 1, height = 1 },
			{ class = "label", label = "𝗡𝗼𝗺𝗯𝗿𝗲 𝗱𝗲 𝗰𝗮𝗽𝗶𝘁𝘂𝗹𝗼", x = 2, y = 0, width = 1, height = 1 }
        }

        for i = 1, chapter_count do
            table.insert(gui, { class = "checkbox", name = "chapter_" .. i, label = "Chapter " .. i .. ":", x = 0, y = i })
            table.insert(gui, { class = "dropdown", name = "chapter_" .. i .. "_lang", items = items_idiomas, value = idiomas["es"], x = 1, y = i })
            table.insert(gui, { class = "edit", name = "chapter_" .. i .. "_name", value = "", hint = "Nombre de capítulo", x = 2, y = i, width = 10 })
        end

        return gui
    end

    local chapter_count = 5
    local buttons = { "Agregar", "Cancelar", "Chapter +1" }

    while true do
        local gui = construir_gui_chapters(chapter_count)
        local pressed, res = aegisub.dialog.display(gui, buttons)

        if pressed == "Cancelar" or pressed == false then
            return
        elseif pressed == "Agregar" then
            local lineas = {}

            for i = 1, chapter_count do
                if res["chapter_" .. i] and res["chapter_" .. i .. "_name"] ~= "" then
                    -- Aquí se usa el código del idioma y no el nombre
                    local codigo_idioma = nombres_a_claves[res["chapter_" .. i .. "_lang"]]
                    table.insert(lineas, string.format("{:chapter %s}%s", codigo_idioma, res["chapter_" .. i .. "_name"]))
                end
            end

			for i = #lineas, 1, -1 do
				subs.insert(1, {
					class = "dialogue",
					text = lineas[i],
					layer = 0,
					start_time = 0,
					end_time = 0,
					style = "Default",
					actor = "SAI",
					margin_l = 0,
					margin_r = 0,
					margin_t = 0,
					effect = "",
					comment = true
				})
			end

            aegisub.set_undo_point("Agregar capítulos")
            return
        elseif pressed == "Chapter +1" then
            chapter_count = chapter_count + 1
        end
    end
end

-- "Configuración" - GUI para definir la ruta de sai.exe
local function configurar()
    local config = cargar_configuracion()
    local dialog_config = {
        { class = "label", label = "Ruta a sai.exe:", x = 0, y = 0 },
        { class = "edit", name = "ruta_sai", value = config.ruta_sai, x = 1, y = 0, width = 20 },
        { class = "label", label = "Ruta a mkvmerge.exe:", x = 0, y = 1 },
        { class = "edit", name = "ruta_mkvmerge", value = config.ruta_mkvmerge, x = 1, y = 1, width = 20 }
   }

	local buttons = { "Guardar", "SAI...", "MKVMerge...", "Cancelar" } -- Orden ajustado
	while true do
		local pressed, res = aegisub.dialog.display(dialog_config, buttons)
		if pressed == "Guardar" then
			config.ruta_sai = res.ruta_sai
			config.ruta_mkvmerge = res.ruta_mkvmerge -- Asegúrate de guardar esta nueva ruta también
			guardar_configuracion(config)
			return
		elseif pressed == "SAI..." then
			local ruta_archivo = aegisub.dialog.open(
				"Selecciona sai.exe",
				"",
				"",
				"Ejecutable de SAI (*.exe)|*.exe",
				false,
				true
			)
			if ruta_archivo then
				res.ruta_sai = ruta_archivo -- Actualizamos la ruta de SAI
				dialog_config[2].value = ruta_archivo -- También actualizamos el campo edit
			end
		elseif pressed == "MKVMerge..." then
			local ruta_archivo = aegisub.dialog.open(
				"Selecciona mkvmerge.exe",
				"",
				"",
				"Ejecutable de MKVMerge (*.exe)|*.exe",
				false,
				true
			)
			if ruta_archivo then
				res.ruta_mkvmerge = ruta_archivo -- Actualizamos la ruta de Mkvmerge
				dialog_config[4].value = ruta_archivo -- También actualizamos el campo edit para Mkvmerge
				print("Ruta de Mkvmerge seleccionada: " .. ruta_archivo)
			end
		elseif pressed == "Cancelar" or pressed == false then
			return
		end
	end
end

-- Definir las extensiones en un lugar centralizado
local extensiones = {
    video = "Archivo de video (*.mkv; *.mp4; *.avi; *.webm; *.mov; *.ts; *.m2ts; *.wmv; *.hevc; *.h264; *.h265)|*.mkv;*.mp4;*.avi;*.webm;*.mov;*.ts;*.m2ts;*.wmv;*.hevc;*.h264;*.h265",
    audio = "Archivo de audio (*.mp3; *.wav; *.flac; *.eac3; *.aac; *.mka; *.opus; *.ac3; *.ogg; *.dts; *.wma)|*.mp3;*.wav;*.flac;*.eac3;*.aac;*.mka;*.opus;*.ac3;*.ogg;*.dts;*.wma",
    extraAudio = "Archivo de audio extra (*.mp3; *.wav; *.flac; *.eac3; *.aac; *.mka; *.opus; *.ac3; *.ogg; *.dts; *.wma)|*.mp3;*.wav;*.flac;*.eac3;*.aac;*.mka;*.opus;*.ac3;*.ogg;*.dts;*.wma",
    extraSubs = "Archivo de subtítulo extra (*.srt; *.ass; *.mks)|*.srt;*.ass;*.mks",
    insertSubs = "Archivo de subtítulos insert (*.srt; *.ass; *.mks)|*.srt;*.ass;*.mks",
    fonts = "Fuentes (*.ttf; *.otf)|*.ttf;*.otf"
}

-- Agregar rutas de archivos y carpetas automáticamente sin depender de selección
local function agregar_rutas(subs, sel)
    local count = 0  -- Contador de líneas editadas, para saber si se hizo algo

    -- Recorrer todas las líneas del script
    for i = 1, #subs do
        local line = subs[i]
        if line.class == "dialogue" then
            -- Ajuste para capturar el tag, idioma y nombre de pista correctamente
            local tag, idioma, nombre_pista = line.text:match("{:([%w]+)%s?([%w%-]*)}%[?([^%]]*)%]?")

            -- Validar que el tag exista y sea uno de los conocidos
            if tag and extensiones[tag] or tag == "fonts" or tag == "insert" then
                local ruta_seleccionada

                if tag == "fonts" then
                    -- Seleccionar un archivo de fuente para obtener la carpeta base
                    ruta_seleccionada = aegisub.dialog.open("Selecciona una fuente dentro de una carpeta", "", "", extensiones.fonts)
                    if ruta_seleccionada then
                        -- Extraer solo la carpeta de la ruta seleccionada
                        ruta_seleccionada = ruta_seleccionada:match("^(.*[/\\])")
                        -- Eliminar la barra diagonal al final si existe
                        if ruta_seleccionada:sub(-1) == "\\" or ruta_seleccionada:sub(-1) == "/" then
                            ruta_seleccionada = ruta_seleccionada:sub(1, -2)
                        end
                    end

                elseif tag == "insert" then
                    -- Seleccionar archivos de subtítulos para inserts
                    ruta_seleccionada = aegisub.dialog.open("Selecciona el archivo de subtítulos para insert", "", "", extensiones.insertSubs)

                elseif extensiones[tag] then
                    -- Determinar un nombre descriptivo para el tipo de archivo
                    local tipo_descriptivo = {
                        video = "video",
                        audio = "audio",
                        extraAudio = "audio extra",
                        extraSubs = "subtítulo extra",
                        insert = "subtítulo para insert",
                        fonts = "fuente",
                        subLang = "subtítulo",
                    }
                    local tipo = tipo_descriptivo[tag] or tag

					-- Armar una breve descripción de la línea actual
					local info_linea = ""
					if idioma ~= "" then info_linea = info_linea .. idioma end
					if nombre_pista ~= "" then
						info_linea = info_linea ~= "" and info_linea .. " - " .. nombre_pista or nombre_pista
					end
					if info_linea ~= "" then
						info_linea = " (" .. info_linea .. ")"
					end

					-- Mostrar diálogo con descripción contextual
					ruta_seleccionada = aegisub.dialog.open("Selecciona el archivo de " .. tipo .. info_linea, "", "", extensiones[tag])
                end

                if ruta_seleccionada then
                    -- Agregar la ruta seleccionada al texto
                    if idioma ~= "" and nombre_pista ~= "" then
                        line.text = string.format("{:%s %s}[%s]%s", tag, idioma, nombre_pista, ruta_seleccionada)
                    elseif idioma ~= "" then
                        line.text = string.format("{:%s %s}%s", tag, idioma, ruta_seleccionada)
                    else
                        line.text = string.format("{:%s}%s", tag, ruta_seleccionada)
                    end

                    -- Si se ha agregado la ruta, se limpia el campo de efecto
                    line.effect = ""

                    -- Guardar la línea modificada
                    subs[i] = line
                    count = count + 1
                end
            end
        end
    end

    -- Mostrar mensaje si no se editó ninguna línea
    if count == 0 then
        aegisub.dialog.display(
            { {class="label", label="No se encontraron líneas válidas para agregar rutas."} },
            {"OK"}
        )
    end

    aegisub.set_undo_point("Agregar rutas de archivos y carpetas")
end

-- Registro en el menú principal
aegisub.register_macro("SAI Muxer/Agregar líneas de pistas", "Agrega líneas de configuración al inicio del subtítulo", agregar_lineas)
aegisub.register_macro("SAI Muxer/Agregar líneas de capítulos", "Agrega capítulos a la configuración de SAI", agregar_chapters)
aegisub.register_macro("SAI Muxer/Agregar rutas en líneas de pistas...", "Agrega rutas a las líneas seleccionadas", agregar_rutas)
aegisub.register_macro("SAI Muxer/Multiplexar", "Ejecuta el comando de multiplexado", muxear)
aegisub.register_macro("SAI Muxer/Configuración", "Configura la ruta a sai.exe", configurar)