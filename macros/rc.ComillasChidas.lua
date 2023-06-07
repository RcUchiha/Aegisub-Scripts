script_name = "Comillas Chidas"
script_description = "Reemplaza las comillas simples en el texto de las líneas seleccionadas por comillas de apertura (“) y de cierre (”)"
script_author = "CiferrC"
script_version = "1.1"

-- Variable global para rastrear si la siguiente comilla debe ser de apertura o cierre
esComillaApertura = true

-- Función para cambiar las comillas en una línea
function cambiarComillas(subtitles, selected_lines, active_line)
    for _, index in ipairs(selected_lines) do
        local linea = subtitles[index]

        -- Solo reemplaza las comillas fuera de los corchetes {}
        local nuevaLinea = linea.text:gsub("({[^}]*})", function(match) return match:gsub('"', '\1') end)
        nuevaLinea = nuevaLinea:gsub('"', function()
            if esComillaApertura then
                esComillaApertura = false
                return '“'
            else
                esComillaApertura = true
                return '”'
            end
        end)
        nuevaLinea = nuevaLinea:gsub('\1', '"')

        linea.text = nuevaLinea
        subtitles[index] = linea
    end
end

-- Registrar la automatización en Aegisub
aegisub.register_macro(script_name, script_description, cambiarComillas)
