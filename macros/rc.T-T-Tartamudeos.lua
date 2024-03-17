script_name = "T-T-Tartamudeos"
script_description = "Encuentra y señala las líneas con tartamudeos faltantes o erróneos."
script_author = "CiferrC"
script_version = "1.1"

menu_embedding = "CiferrC/"

function tartamudeo(subtitles, selected_lines, active_line)
    local tartamudeos = {"A%-A", "B%-B", "C%-C", "D%-D", "E%-E", "F%-F", "G%-G", "H%-H", "I%-I", "J%-J", "K%-K", "L%-L", "M%-M", "N%-N", "Ñ%-Ñ", "O%-O", "P%-P", "Q%-Q", "R%-R", "S%-S", "T%-T", "U%-U", "V%-V", "W%-W", "X%-X", "Y%-Y", "Z%-Z"}

    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        local comentarios = line.text:match("{(.-)}") or ""
        local textoSinComentarios = line.text:gsub("{(.-)}", "")
        local leyendaExistente = line.effect ~= "" and line.effect or nil

        local tartamudeoEnComentario = false
        local tartamudeoEnTexto = false
        local tartamudeoErroneo = false
        local tartamudeoDobleFaltante = false

        -- Comprobación del tartamudeo
        for _, t in ipairs(tartamudeos) do
            if comentarios:find("%u%l%-%u%l") and not textoSinComentarios:find("%u%l%-%u%l") then
                tartamudeoDobleFaltante = true
            elseif comentarios:find(t) then
                tartamudeoEnComentario = true
            end
        end

        for _, t in ipairs(tartamudeos) do
            if textoSinComentarios:find(t) then
                tartamudeoEnTexto = true
            end
        end

        -- Encuentra un tartamudeo erróneo
        local tartamudeoErroneoEncontrado = textoSinComentarios:match("%u%-%u")
        if tartamudeoErroneoEncontrado and not tartamudeoEnTexto then
            tartamudeoErroneo = true
        end

        -- Añade leyendas
        if tartamudeoDobleFaltante then
            line.effect = leyendaExistente and leyendaExistente .. " / Tartamudeo de dos letras faltante" or "Tartamudeo de dos letras faltante"
            subtitles[i] = line
        elseif tartamudeoEnComentario and not tartamudeoEnTexto and not tartamudeoErroneo then
            line.effect = leyendaExistente and leyendaExistente .. " / Tartamudeo faltante" or "Tartamudeo faltante"
            subtitles[i] = line
        elseif tartamudeoErroneo then
            line.effect = leyendaExistente and leyendaExistente .. " / Tartamudeo erróneo" or "Tartamudeo erróneo"
            subtitles[i] = line
        end
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(menu_embedding..script_name, script_description, tartamudeo)
