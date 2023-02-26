using Javis

function ground(args...)
    background("white") # canvas background
    sethue("black") # pen color
end

function object(p=O, color="black")
    sethue(color)
    circle(p, 25, :fill)
    return p
end

function path!(points, pos, color)
    sethue(color)
    push!(points, pos) # add pos to points
    circle.(points, 2, :fill) # draws a circle for each point using broadcasting
end

function connector(p1, p2, color)
    sethue(color)
    line(p1,p2, :stroke)
end

myvideo = Video(500, 500)

path_of_red = Point[]
path_of_blue = Point[]

Background(1:70, ground)
red_ball = Object(1:70, (args...)->object(O, "red"), Point(100,0))
act!(red_ball, Action(anim_rotate_around(2π, O)))
blue_ball = Object(1:70, (args...)->object(O, "blue"), Point(200,80))
act!(blue_ball, Action(anim_rotate_around(2π, 0.0, red_ball)))
Object(1:70, (args...)->connector(pos(red_ball), pos(blue_ball), "black"))
Object(1:70, (args...)->path!(path_of_red, pos(red_ball), "red"))
Object(1:70, (args...)->path!(path_of_blue, pos(blue_ball), "blue"))

render(myvideo; pathname="tutorial_1.gif")

# tutorial 2
using Javis
function ground(args...)
    background("black")
    sethue("white")
end

frames = 1000

myvideo = Video(500, 500)
Background(1:frames, ground)

earth = Object(1:frames, JCircle(O, 10, color = "blue", action = :fill), Point(200, 0))
venus = Object(JCircle(O, 7, color = "red", action = :fill), Point(144, 0))

earth_orbit = Object(@JShape begin
    sethue(color)
    setdash(edge)
    circle(O, 200, action)
end color = "white" action = :stroke edge = "solid")

venus_orbit = Object(@JShape begin
    sethue(color)
    setdash(edge)
    circle(O, 144, action)
end color = "white" action = :stroke edge = "solid")

act!(earth, Action(anim_rotate_around(12.5 * 2π * (224.7 / 365), O)))
act!(venus, Action(anim_rotate_around(12.5 * 2π, O)))

connection = [] # To store the connectors
Object(@JShape begin
    sethue(color)
    push!(connection, [p1, p2])
    map(x -> line(x[1], x[2], :stroke), connection)
end connection = connection p1 = pos(earth) p2 = pos(venus) color = "#f05a4f")

render(myvideo; pathname = "cosmic_dance.gif")

# tutorial 3
using Random
using Javis
video = Video(500, 500)
function ground(args...)
    background("white")
    sethue("black")
end

function circ(p = O, color = "black", action = :fill, radius = 25, edge = "solid")
    sethue(color)
    setdash(edge)
    circle(p, radius, action)
end

head = Object((args...) -> circ(O, "black", :stroke, 170))

function draw_line(p1 = O, p2 = O, color = "black", action = :stroke, edge = "solid")
    sethue(color)
    setdash(edge)
    line(p1, p2, action)
end

inside_circle = Object((args...) -> circ(O, "black", :stroke, 140, "longdashed"))
vert_line = Object(
    (args...) ->
        draw_line(Point(0, -170), Point(0, 170), "black", :stroke, "longdashed"),
)
horiz_line = Object(
    (args...) ->
        draw_line(Point(-170, 0), Point(170, 0), "black", :stroke, "longdashed"),
)

function electrode(
    p = O,
    fill_color = "white",
    outline_color = "black",
    action = :fill,
    radius = 25,
    circ_text = "",
)
    sethue(fill_color)
    circle(p, radius, :fill)
    sethue(outline_color)
    circle(p, radius, :stroke)
    text(circ_text, p, valign = :middle, halign = :center)
end

electrodes_list = [
    (name = "Cz", position = O),
    (name = "C3", position = Point(-70, 0)),
    (name = "C4", position = Point(70, 0)),
    (name = "T3", position = Point(-140, 0)),
    (name = "T4", position = Point(140, 0)),
    (name = "Pz", position = Point(0, 70)),
    (name = "P3", position = Point(-50, 70)),
    (name = "P4", position = Point(50, 70)),
    (name = "Fz", position = Point(0, -70)),
    (name = "F3", position = Point(-50, -70)),
    (name = "F4", position = Point(50, -70)),
    (name = "F8", position = Point(115, -80)),
    (name = "F7", position = Point(-115, -80)),
    (name = "T6", position = Point(115, 80)),
    (name = "T5", position = Point(-115, 80)),
    (name = "Fp2", position = Point(40, -135)),
    (name = "Fp1", position = Point(-40, -135)),
    (name = "A1", position = Point(-190, -10)),
    (name = "A2", position = Point(190, -10)),
    (name = "O1", position = Point(-40, 135)),
    (name = "O2", position = Point(40, 135)),
]

radius = 15 # Radius of the electrodes
for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                "white",
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end

indicators = ["white", "gold1", "darkolivegreen1", "tomato"]

for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                rand(indicators, length(electrodes_list)),
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end
for num in 1:length(electrodes_list)
    Object(
        (args...) ->
            electrode.(
                electrodes_list[num].position,
                rand(indicators, length(electrodes_list)),
                "black",
                :fill,
                radius,
                electrodes_list[num].name,
            ),
    )
end

function info_box(video, object, frame)
    fontsize(12)
    box(140, -210, 170, 40, :stroke)
    text("10-20 EEG Array Readings", 140, -220, valign = :middle, halign = :center)
    text("t = $(frame)s", 140, -200, valign = :middle, halign = :center)
end

info = Object(info_box)
render(demo, pathname = "eeg.gif", framerate = 1)