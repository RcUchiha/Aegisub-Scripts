script_name = "Comillas Chidas"
script_description = "Reemplaza las comillas simples en el texto de las líneas seleccionadas por comillas latinas de apertura (“) y cierre (”)"
script_author = "CiferrC"
script_version = "1.4"

menu_embedding = "CiferrC/"

-- Función para cambiar las comillas en una línea
function cambiarComillas(subtitles, selected_lines, active_line)
    for _, index in ipairs(selected_lines) do
        local linea = subtitles[index]

        -- Extraer y almacenar los comentarios para evitar verificarlos
        local comentarios = {}
        local nuevaLinea = linea.text:gsub("({[^}]*})", function(match) 
            table.insert(comentarios, match)
            return "{}"
        end)

        -- Reemplaza las comillas simples al inicio de una palabra con comillas latinas de apertura
        -- Incluye palabras que comienzan con letras acentuadas y otros caracteres
        nuevaLinea = nuevaLinea:gsub('"[%wÁÉÍÓÚáéíóúôōûū~]', function(match) return '“' .. match:sub(2) end)

        -- Reemplaza las comillas simples al final de una palabra con comillas latinas de cierre
        -- Incluye palabras que terminan con letras acentuadas y otros caracteres
        nuevaLinea = nuevaLinea:gsub('[%wÁÉÍÓÚáéíóúôōûū~]"', function(match) return match:sub(1, -2) .. '”' end)

        -- Verifica si hay comillas por fuera de signos de exclamación
        if nuevaLinea:find('"%¡') or nuevaLinea:find('!%"') then
            if linea.effect and #linea.effect > 0 then
                linea.effect = linea.effect .. " / Comillas por fuera de exclamación"
            else
                linea.effect = "Comillas por fuera de exclamación"
            end
            nuevaLinea = nuevaLinea .. " {NOTA: Los signos de exclamación se ponen dentro de las comillas (“¡ !”) solo si se trata de una cita exclamativa.}"
        end

        -- Verifica si hay comillas por fuera de signos de interrogación
        if nuevaLinea:find('"%¿') or nuevaLinea:find('?%"') then
            if linea.effect and #linea.effect > 0 then
                linea.effect = linea.effect .. " / Comillas por fuera de interrogación"
            else
                linea.effect = "Comillas por fuera de interrogación"
            end
            nuevaLinea = nuevaLinea .. " {NOTA: Los signos de interrogación se ponen dentro de las comillas (“¿ ?”) solo si se trata de una cita interrogativa.}"
        end

        -- Verifica si hay comillas después del punto
        if nuevaLinea:find('%."') then
            if linea.effect and #linea.effect > 0 then
                linea.effect = linea.effect .. " / Comillas por fuera de punto"
            else
                linea.effect = "Comillas por fuera de punto"
            end
            nuevaLinea = linea.text .. " {NOTA: El punto final bajo ninguna circunstancia va dentro de las comillas (“___.”). [https://www.fundeu.es/consulta/las-comillas-y-el-punto-final-6553/]}"
        end

        -- Inserta los comentarios de nuevo en su lugar original
        local i = 0
        nuevaLinea = nuevaLinea:gsub("({})", function() 
            i = i + 1
            return comentarios[i]
        end)

        linea.text = nuevaLinea
        subtitles[index] = linea
    end
end

-- Registrar la automatización en Aegisub
aegisub.register_macro(menu_embedding..script_name, script_description, cambiarComillas)
