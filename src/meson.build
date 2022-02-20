# Populate constants with meson build data
build_info = configuration_data ()
build_info.set_quoted('PROJECT_NAME', meson.project_name())
build_info.set_quoted('VERSION', meson.project_version())

build_constants = configure_file (
    input: join_paths ('Constants', 'Build.vala.in'),
    output: 'Build.vala',
    configuration: build_info
)

common_sources = files (
    'Application.vala',
    'ColorPalette.vala',
    'Drawable.vala',
    'Editable.vala',
    'MainWindow.vala',
    'Point.vala',
    'Rectangle.vala',
    'State.vala',
    'Stepper.vala',
    'Constants/Const.vala',
    'HashLife/Pair.vala',
    'HashLife/Quad.vala',
    'HashLife/QuadFactory.vala',
    'HashLife/Quadruplet.vala',
    'HashLife/QuadTree.vala',
    'HashLife/Simulation.vala',
    'Widgets/DrawingBoard.vala',
    'Widgets/HeaderBar.vala',
    'Widgets/PlaybackBar.vala',
    'Widgets/ScrolledBoard.vala'
)

common_sources += build_constants

sources = common_sources + files (
    'Main.vala'
)
