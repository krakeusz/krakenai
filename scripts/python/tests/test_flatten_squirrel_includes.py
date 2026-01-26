from scripts.python.flatten_squirrel_includes import process_source_line

def test__process_source_line__converts_an_include() -> None:
    line = 'require("road_helpers/TruckOrders.nut")'
    expected_output = 'require("TruckOrders.nut")'
    
    assert process_source_line(line) == expected_output

def test__process_source_line__doesnt_change_regular_line() -> None:
    line = '	function InitializePath(sources, goals, ignoreTiles=[]) {'
    
    assert process_source_line(line) == line

def test__process_source_file(fs: FakeFilesystem) -> None:
    fs.