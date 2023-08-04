script_name = "Comillas Chidas"
script_description = "Reemplaza las comillas simples en el texto de las líneas seleccionadas por comillas latinas de apertura (“) y cierre (”)"
script_author = "CiferrC"
script_version = "1.3"

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

        -- Reemplaza las comillas al inicio de una palabra con comillas de apertura
        -- Incluye palabras que comienzan con letras acentuadas
        nuevaLinea = nuevaLinea:gsub('"[%wÁÉÍÓÚáéíóú]', function(match) return '“' .. match:sub(2) end)

        -- Reemplaza las comillas al final de una palabra con comillas de cierre
        -- Incluye palabras que terminan con letras acentuadas
        nuevaLinea = nuevaLinea:gsub('[%wÁÉÍÓÚáéíóú]"', function(match) return match:sub(1, -2) .. '”' end)

        -- Verifica si hay comillas antes de los signos de apertura ¡ y ¿, o después de los signos de cierre ! y ?
        if nuevaLinea:find('"%¡') or nuevaLinea:find('"%¿') or nuevaLinea:find('!%"') or nuevaLinea:find('?%"') then
            -- Si hay, agrega el aviso al campo "Efecto" precedido por una barra diagonal (/) y espacios si ya hay un comentario
            if linea.effect and #linea.effect > 0 then
                linea.effect = linea.effect .. " / Comillas por fuera de signos"
            else
                linea.effect = "Comillas por fuera de signos"
            end
            nuevaLinea = linea.text
        end

        -- Verifica si hay comillas después del punto
        if nuevaLinea:find('%."') then
            -- Si hay, agrega un aviso diferente al campo "Efecto" precedido por una barra diagonal (/) y espacios si ya hay un comentario
            if linea.effect and #linea.effect > 0 then
                linea.effect = linea.effect .. " / Comillas por fuera de punto"
            else
                linea.effect = "Comillas por fuera de punto"
            end
            nuevaLinea = linea.text
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
