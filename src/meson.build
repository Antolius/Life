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
    'Pattern.vala',
    'Point.vala',
    'Rectangle.vala',
    'Scaleable.vala',
    'Shape.vala',
    'State.vala',
    'Stepper.vala',
    'Constants/Const.vala',
    'HashLife/Cache/Frequency.vala',
    'HashLife/Cache/LfuCache.vala',
    'HashLife/Cache/LoadingCache.vala',
    'HashLife/Cache/MonitoredCache.vala',
    'HashLife/Cache/Node.vala',
    'HashLife/Pair.vala',
    'HashLife/Quad.vala',
    'HashLife/QuadFactory.vala',
    'HashLife/Quadruplet.vala',
    'HashLife/QuadTree.vala',
    'HashLife/Simulation.vala',
    'Stats/Counter.vala',
    'Stats/Gauge.vala',
    'Stats/Metric.vala',
    'Stats/MetricVisitor.vala',
    'Stats/Timer.vala',
    'Widgets/DrawingBoard.vala',
    'Widgets/EditingBoard.vala',
    'Widgets/HeaderBar.vala',
    'Widgets/LibraryPane.vala',
    'Widgets/PatternLibraryRow.vala',
    'Widgets/PlaybackBar.vala',
    'Widgets/ScrolledBoard.vala',
    'Widgets/SimulationPane.vala',
    'Widgets/StatsOverlay.vala'
)

common_sources += build_constants

sources = common_sources + files (
    'Main.vala'
)
