-- Check if the js_ReaScriptAPI extension is installed
if not reaper.JS_Dialog_BrowseForFolder then
  reaper.ShowMessageBox("This script requires the 'js_ReaScriptAPI' extension. Please install it to continue.", "Lỗi", 0)
  return
end

-- Select the folder containing the audio files
local retval, folder = reaper.JS_Dialog_BrowseForFolder("Chọn thư mục chứa audio files", "")
if not retval or not folder or folder == "" then return end

-- Select the CSV file
local retval_csv, csv_path = reaper.GetUserFileNameForRead("", "Chọn file CSV", "csv")
if not retval_csv or not csv_path or csv_path == "" then return end

-- Read the CSV file
local csv = io.open(csv_path, "r")
if not csv then
  reaper.ShowMessageBox("Không thể mở file CSV!", "Lỗi", 0)
  return
end

-- Map variation to track index
local variation_tracks = {}
local track_count = 0

reaper.Undo_BeginBlock()

for line in csv:lines() do
  local pos, filename, marker_name, variation = line:match("([^,]+),([^,]+),?([^,]*),?([^,]*)")
  if pos and filename then
    local time = tonumber(pos)
    variation = tonumber(variation) or 1

    -- Create a track for the variation if it doesn't exist
    if not variation_tracks[variation] then
      reaper.InsertTrackAtIndex(track_count, true)
      variation_tracks[variation] = reaper.GetTrack(0, track_count)
      track_count = track_count + 1
    end
    local track = variation_tracks[variation]

    -- Insert a marker if a name is provided
    if marker_name and marker_name ~= "" then
      reaper.AddProjectMarker(0, false, time, 0, marker_name, -1)
    end

    -- Insert the audio file on the correct track at the correct position
    reaper.SetOnlyTrackSelected(track)
    reaper.SetEditCurPos(time, false, false)
    -- Use a forward slash for cross-platform compatibilitytremo
    reaper.InsertMedia(folder.."/"..filename, 0)
  end
end

csv:close()
reaper.Undo_EndBlock("Import audio files and markers from CSV", -1)
reaper.UpdateArrange()
