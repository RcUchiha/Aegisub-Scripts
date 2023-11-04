script_name="WrapCraft"
script_description="Envuelve el texto con llaves `{}`, ofreciendo la opción de eliminar o conservar etiquetas."
script_author="CiferrC (basado en darkstar901)"
script_version="1.0"

menu_embedding = "CiferrC/"

-- Constantes Globales para reemplazo de caracteres
local NOTEMDASH = "NOTEMDASH"
local FIRSTCLIP = "FIRSTCLIP"
local LASTCLIP  = "LASTCLIP"
local BR        = "_br_"

-- Función para reemplazar o restaurar caracteres especiales
function reemplazar_caracteres_especiales(texto, modo)
    if modo == "codificar" then
        return texto:gsub("-", NOTEMDASH)
                    :gsub("%(", FIRSTCLIP)
                    :gsub("%)", LASTCLIP)
                    :gsub("\\N", BR)
    else
        return texto:gsub(NOTEMDASH, "-")
                    :gsub(FIRSTCLIP, "%(")
                    :gsub(LASTCLIP, "%)")
                    :gsub(BR, "\\N")
    end
end

-- Función para eliminar las llaves, conservando el contenido interno
function RemoverCorchetes(subs, sel)
    for x, i in ipairs(sel) do
        local linea = subs[i]
        linea.text = reemplazar_caracteres_especiales(linea.text, "codificar") 
        linea.text = linea.text:gsub("{", ""):gsub("}", "")
        linea.text = reemplazar_caracteres_especiales(linea.text, "decodificar")
        subs[i] = linea
    end
end

-- Función para reorganizar las etiquetas y el texto de las líneas seleccionadas
function ReestructurarTexto(subs, sel, eliminarEtiquetas)
    for x, i in ipairs(sel) do
        local linea = subs[i]
        linea.text = reemplazar_caracteres_especiales(linea.text, "codificar")
        
        -- Extraer todas las etiquetas al inicio
        local all_tags = ""
        for tag in linea.text:gmatch("{\\[^}]-}") do
            all_tags = all_tags .. tag
            linea.text = linea.text:gsub(tag, "", 1) -- Remove the matched tag once
        end
        
        -- Mantener la lógica original para los comentarios y otros patrones
        linea.text = linea.text
            :gsub("{<([^\\}]-)>}","{%1}")                -- Restaurar comentario
            :gsub("{([^\\}]-)}","}{<%1>}{")              -- Conservar comentario
            :gsub("{<>|([^\\}]-)|<>}","{<%1>}")          -- Conservar comentario previo
            :gsub("{<>([^\\}]-)<>}","%1")                -- Conservar comentario previo
            :gsub("^([^{]+)","{%1")                      -- Primera { cuando no hay etiquetas
            :gsub("([^}]+)$","%1}")                      -- Última } en última columna
            :gsub("([^}])({\\[^}]-})([^{])","%1}%2{%3")  -- Mantener {} alrededor de las etiquetas
            :gsub("^({\\[^}]-})([^{])","%1{%2")          -- Primera { después del primer conjunto de etiquetas
            :gsub("([^}])({\\[^}]-})$","%1}%2")
            :gsub("{}","")                               -- Eliminar llaves vacías
            :gsub("_br_","\\N")                          -- Devolver salto de línea
        
        -- Quitando llaves innecesarias
        linea.text = linea.text:gsub("}{", "")

        -- Rodeando el texto restante con llaves
        if not linea.text:match("^{.*}$") then
            linea.text = "{" .. linea.text .. "}"
        end
        
        if eliminarEtiquetas then
            all_tags = ""
        end

        linea.text = all_tags .. linea.text

        linea.text = reemplazar_caracteres_especiales(linea.text, "decodificar")
        subs[i] = linea
    end
end

-- Función para mostrar un diálogo al usuario
local function MostrarDialogo(subs, sel)
    local configuracion_dialogo = {
        {class="label", label="¿Desea conservar las etiquetas?", x=0, y=0},
        {class="checkbox", label="Sí", name="conservar_etiquetas", value=true, x=0, y=1},
    }
    
    local btn, resultados_usuario = aegisub.dialog.display(configuracion_dialogo)
    
    if btn then
        local eliminarEtiquetas = not resultados_usuario.conservar_etiquetas
        ReestructurarTexto(subs, sel, eliminarEtiquetas)
    end
end

-- Registrar la función MostrarDialogo como una macro en Aegisub
aegisub.register_macro(menu_embedding..script_name, script_description, MostrarDialogo)