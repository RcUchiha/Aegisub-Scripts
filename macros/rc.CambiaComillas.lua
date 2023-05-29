script_name = "Cambia Comillas"
script_description = "Cambia las comillas simples en el texto de las líneas por comillas de apertura (“) y de cierre (”)"
script_author = "CiferrC"
script_version = "1.0"

-- Función para cambiar las comillas en una línea
function cambiarComillas(subtitles, selected_lines, active_line)
    for _, index in ipairs(selected_lines) do
        local linea = subtitles[index]
        local nuevaLinea = ""

        -- Buscar comillas dobles en la línea
        local inicio, fin = linea.text:find('"')
        if inicio ~= nil and fin ~= nil then
            -- Reemplazar las comillas dobles en la línea con las comillas de apertura y cierre
            local texto = linea.text:gsub('"', '“', 1)
            texto = texto:gsub('"', '”', 1)
            nuevaLinea = texto

            linea.text = nuevaLinea
            subtitles[index] = linea
        end
    end
end

-- Registrar la automatización en Aegisub
aegisub.register_macro(script_name, script_description, cambiarComillas)
