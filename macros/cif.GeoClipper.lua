script_name = "GeoClipper"
script_description = "Convierte un clip cuadrado a diversas figuras geométricas."
script_author = "CiferrC"
script_version = "0.1"
submenu = "_CiferrC's Scripts/"

local function generar_figura(tipo, x1, y1, x2, y2)
    local cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
    local rx, ry = (x2 - x1) / 2, (y2 - y1) / 2
    local points = {}

    if tipo == "Círculo" then
        local r = math.min(rx, ry)
        for angle = 0, 360, 360 / 64 do
            local radians = math.rad(angle)
            local px = cx + r * math.cos(radians)
            local py = cy + r * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Elipse" then
        for angle = 0, 360, 360 / 64 do
            local radians = math.rad(angle)
            local px = cx + rx * math.cos(radians)
            local py = cy + ry * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Triángulo equilátero" then
        for angle = 0, 360, 120 do
            local radians = math.rad(angle - 90)
            local px = cx + rx * math.cos(radians)
            local py = cy + ry * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Triángulo rectángulo" then
        points = {
            string.format("%.2f %.2f", x1, y1),
            string.format("%.2f %.2f", x2, y2),
            string.format("%.2f %.2f", x1, y2)
        }
    elseif tipo == "Pentágono" then
        for angle = 0, 360, 360 / 5 do
            local radians = math.rad(angle - 90)
            local px = cx + rx * math.cos(radians)
            local py = cy + ry * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Hexágono" then
        for angle = 0, 360, 360 / 6 do
            local radians = math.rad(angle - 90)
            local px = cx + rx * math.cos(radians)
            local py = cy + ry * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Octágono" then
        for angle = 0, 360, 360 / 8 do
            local radians = math.rad(angle - 90)
            local px = cx + rx * math.cos(radians)
            local py = cy + ry * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Estrella de 4 puntas" or tipo == "Estrella de 5 puntas" or tipo == "Estrella de 6 puntas" then
        local num_puntas = tipo == "Estrella de 4 puntas" and 4 or tipo == "Estrella de 5 puntas" and 5 or 6
        local radios = {rx, rx * 0.5} -- Ajuste proporcional para puntas internas
        local pasos = num_puntas * 2

        for i = 0, pasos - 1 do
            local angle = i * (360 / pasos)
            local radians = math.rad(angle - 90)
            local r = radios[(i % 2) + 1]
            local px = cx + r * math.cos(radians)
            local py = cy + r * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Rombo" then
        points = {
            string.format("%.2f %.2f", cx, y1),
            string.format("%.2f %.2f", x2, cy),
            string.format("%.2f %.2f", cx, y2),
            string.format("%.2f %.2f", x1, cy)
        }
    elseif tipo == "Trapezoide" then
        local top_width = rx * 0.6
        points = {
            string.format("%.2f %.2f", cx - top_width, y1),
            string.format("%.2f %.2f", cx + top_width, y1),
            string.format("%.2f %.2f", x2, y2),
            string.format("%.2f %.2f", x1, y2)
        }
    elseif tipo == "Romboide" then
        points = {
            string.format("%.2f %.2f", x1, y1),
            string.format("%.2f %.2f", x2, y1),
            string.format("%.2f %.2f", x2 + rx * 0.6, y2),
            string.format("%.2f %.2f", x1 + rx * 0.6, y2)
        }
    elseif tipo == "Semicírculo" then
        local r = rx
        for angle = 0, 180, 180 / 64 do
            local radians = math.rad(angle)
            local px = cx + r * math.cos(radians)
            local py = cy + r * math.sin(radians)
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    elseif tipo == "Corazón" then
        local scale_x = rx * 1.2
        local scale_y = ry * 1.2
        for angle = 0, 360, 360 / 64 do
            local radians = math.rad(angle)
            local px = cx + scale_x * 0.7 * math.sin(radians)^3
            local py = cy - scale_y * (0.3 * math.cos(radians) - 0.15 * math.cos(2 * radians) - 0.05 * math.cos(3 * radians) - 0.01 * math.cos(4 * radians))
            table.insert(points, string.format("%.2f %.2f", px, py))
        end
    end

    return "m " .. table.concat(points, " l ")
end

local function convertir_figuras(subs, sel, figura)
    for _, i in ipairs(sel) do
        local line = subs[i]
        local text = line.text

        local clip = text:match("\\clip%(([%d%.,%s%-]+)%)")
        if clip then
            local coords = {}
            for coord in clip:gmatch("[%d%.%-]+") do
                table.insert(coords, tonumber(coord))
            end

            if #coords == 4 then
                local figura_shape = generar_figura(figura, coords[1], coords[2], coords[3], coords[4])
                line.text = text:gsub("\\clip%([%d%.,%s%-]+%)", "\\clip(" .. figura_shape .. ")")
                subs[i] = line
            else
                aegisub.debug.out("Clip cuadrado no válido en línea\n")
            end
        else
            aegisub.debug.out("No se encontró un clip válido en línea\n")
        end
    end
end

function menu_principal(subs, sel)
    local opciones = {
        {class="label", label="Selecciona la figura que deseas generar:", x=0, y=0, width=4, height=1},
        {class="dropdown", name="figura", items={"Círculo", "Elipse", "Triángulo equilátero", "Triángulo rectángulo", "Pentágono", "Hexágono", "Octágono", "Estrella de 4 puntas", "Estrella de 5 puntas", "Estrella de 6 puntas", "Rombo", "Romboide", "Trapezoide", "Corazón", "Semicírculo"}, value="Círculo", x=0, y=1, width=4, height=1}
    }

    local botones = {"Generar", "Cancelar"}
    local resultado, valores = aegisub.dialog.display(opciones, botones)

    if resultado == "Generar" then
        convertir_figuras(subs, sel, valores.figura)
        aegisub.set_undo_point(script_name)
    end
end

aegisub.register_macro(submenu..script_name, script_description, menu_principal)
