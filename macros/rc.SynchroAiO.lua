-- Información de registro
script_name = "Synchro AiO"
script_description = "Funciones para sincronizar, todo en uno: ajuste a keyframes, mediado de intervalos entre tiempos (salida-entrada) y uniones a prueba de parpadeos."
script_author = "CiferrC"
script_version = "1.0"

menu_embedding = "CiferrC/"

-- Función para restar 150 ms al tiempo de inicio de la línea seleccionada
function restarTiempoInicio(subs, sel)
    local keyframes = aegisub.keyframes()

    for _, i in ipairs(sel) do
        if subs[i].class == "dialogue" then
            local line = subs[i]
            local start_new = nil
            local start_kf = aegisub.frame_from_ms(line.start_time)

            for _, kf in ipairs(keyframes) do
                if kf <= start_kf + 2 and kf >= start_kf - 12 then
                    start_new = kf
                    break
                end
            end

            if start_new then
                line.start_time = aegisub.ms_from_frame(start_new)
            else
                line.start_time = line.start_time - 150
            end

            subs[i] = line
        end
    end

    -- Verificar si se debe unir al tiempo final de la línea anterior
    join_to_previous_end(subs, sel)
    
    aegisub.set_undo_point("Restar Tiempo Inicial")
end

-- Función para sumar 350 ms al tiempo final de la línea seleccionada
function sumarTiempoFinal(subs, sel)
    local keyframes = aegisub.keyframes()

    for _, i in ipairs(sel) do
        if subs[i].class == "dialogue" then
            local line = subs[i]
            local end_new = nil
            local end_kf = aegisub.frame_from_ms(line.end_time)

            for _, kf in ipairs(keyframes) do
                if kf <= end_kf + 16 and kf >= end_kf - 10 then
                    end_new = kf
                    break
                end
            end

            if end_new then
                line.end_time = aegisub.ms_from_frame(end_new)
            else
                line.end_time = line.end_time + 350
            end

            subs[i] = line
        end
    end

    aegisub.set_undo_point("Sumar Tiempo Final")
end

-- Función para unir al tiempo final de la línea anterior si es necesario
function join_to_previous_end(subs, sel)
    local i = sel[1]
    if i > 1 then
        local current_line = subs[i]
        local prev_line = subs[i - 1]
        
        local time_diff = current_line.start_time - (prev_line and prev_line.end_time or 0)
        
        if time_diff <= 400 and time_diff >= -500 and prev_line then
            local prev_end_frame = aegisub.frame_from_ms(prev_line.end_time)
            local is_prev_end_keyframe = false
            
            for _, kf in ipairs(aegisub.keyframes()) do
                if kf == prev_end_frame then
                    is_prev_end_keyframe = true
                    break
                end
            end
            
            if not is_prev_end_keyframe then
                if prev_line.end_time > current_line.start_time then
                    prev_line.end_time = current_line.start_time
                else
                    local intermediate_time = (prev_line.end_time + current_line.start_time) / 2
                    
                    prev_line.end_time = intermediate_time
                    current_line.start_time = intermediate_time
                end
            end
            
            subs[i - 1] = prev_line
            subs[i] = current_line
        end
    end
end

-- Registro de las macros con submenú
aegisub.register_macro(menu_embedding..script_name.. "/Tiempo de entrada", script_description, restarTiempoInicio)
aegisub.register_macro(menu_embedding..script_name.. "/Tiempo de salida", script_description, sumarTiempoFinal)
