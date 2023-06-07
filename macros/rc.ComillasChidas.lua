script_name = "Comillas Chidas"
script_description = "Reemplaza las comillas simples en el texto de las líneas seleccionadas por comillas de apertura (“) y de cierre (”)"
script_author = "CiferrC"
script_version = "1.1"

-- Función para cambiar las comillas en una línea
function cambiarComillas(subtitles, selected_lines, active_line)
    for _, index in ipairs(selected_lines) do
        local linea = subtitles[index]

        -- Primero reemplaza las comillas dentro de los corchetes {} para que no sean alteradas
        local nuevaLinea = linea.text:gsub("({[^}]*})", function(match) return match:gsub('"', '\1') end)

        -- Reemplaza las comillas al inicio de una palabra con comillas de apertura
        nuevaLinea = nuevaLinea:gsub('"%w', function(match) return '“' .. match:sub(2) end)

        -- Reemplaza las comillas al final de una palabra con comillas de cierre
        nuevaLinea = nuevaLinea:gsub('%w"', function(match) return match:sub(1, -2) .. '”' end)

        -- Restaura las comillas dentro de los corchetes {} a su estado original
        nuevaLinea = nuevaLinea:gsub('\1', '"')

        linea.text = nuevaLinea
        subtitles[index] = linea
    end
end

-- Registrar la automatización en Aegisub
aegisub.register_macro(script_name, script_description, cambiarComillas)
