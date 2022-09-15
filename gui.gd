extends PanelContainer

var logger := Logger.new("VTubeStudioGUI")

func _init() -> void:
	var sc := ScrollContainer.new()
	ControlUtil.all_expand_fill(sc)
	
	add_child(sc)
	
	var vbox := VBoxContainer.new()
	ControlUtil.h_expand_fill(vbox)
	
	sc.add_child(vbox)

	vbox.add_child(_toggle_tracking())

func _toggle_tracking() -> Button:
	var r := Button.new()
	ControlUtil.h_expand_fill(r)
	ControlUtil.no_focus(r)
	r.text = tr("VTUBE_STUDIO_TOGGLE_TRACKING_BUTTON_START")
	r.hint_tooltip = tr("VTUBE_STUDIO_TOGGLE_TRACKING_BUTTON_HINT")

	r.connect("pressed", self, "_on_toggle_tracking", [r])

	return r

func _on_toggle_tracking(button: Button) -> void:
	var trackers = get_tree().current_scene.get("trackers")
	if typeof(trackers) != TYPE_DICTIONARY:
		logger.error(tr("VTUBE_STUDIO_INCOMPATIBLE_RUNNER_ERROR"))
		return

	var tracker: TrackingBackendTrait
	var found := false
	for i in trackers.values():
		if i is TrackingBackendTrait and i.get_name() == "VTubeStudio":
			tracker = i
			found = true
			break

	if found:
		logger.debug("Stopping vts tracker")

		tracker.stop_receiver()
		trackers.erase(tracker.get_name())

		button.text = tr("VTUBE_STUDIO_TOGGLE_TRACKING_BUTTON_START")
	else:
		logger.debug("Starting vts tracker")

		var res: Result = Safely.wrap(AM.em.load_resource("VTubeStudio", "vts.gd"))
		if res.is_err():
			logger.error(res)
			return

		var ifm = res.unwrap().new()

		trackers[ifm.get_name()] = ifm

		button.text = tr("VTUBE_STUDIO_TOGGLE_TRACKING_BUTTON_STOP")
	
	AM.ps.publish(Globals.TRACKER_TOGGLED, not found, "VTubeStudio")
