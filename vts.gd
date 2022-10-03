extends TrackingBackendTrait

## https://github.com/DenchiSoft/VTubeStudio
## https://github.com/Inochi2D/facetrack-d/blob/main/source/ft/adaptors/vtsproto.d

const ConfigTrackerAddress: String = "VTUBE_STUDIO_TRACKER_ADDRESS"

const EMPTY_VEC3_DICT := {"x": 0.0, "y": 0.0, "z": 0.0}

# Example data
# {
# 	"Timestamp":1664817520079,
# 	"Hotkey":-1,
# 	"FaceFound":true,
# 	"Rotation": {
# 		"x":-11.091268539428711,
# 		"y":9.422998428344727,
# 		"z":3.1646311283111574
# 	},
# 	"Position": {
# 		"x":0.4682624340057373,
# 		"y":1.3167941570281983,
# 		"z":4.734524726867676
# 	},
# 	"EyeLeft": {
# 		"x":3.5520474910736086,
# 		"y":9.085052490234375,
# 		"z":0.5114284753799439
# 	},
# 	"EyeRight": {
# 		"x":3.459942579269409,
# 		"y":12.89495849609375,
# 		"z":0.7132274508476257
# 	},
# 	"BlendShapes":
# 	[
# 		{"k":"EyeBlinkRight","v":0.002937057288363576},
# 		{"k":"EyeWideRight","v":0.28645533323287966},
# 		{"k":"MouthLowerDownLeft","v":0.06704049557447434},
# 		{"k":"MouthRollUpper","v":0.10249163955450058},
# 		{"k":"CheekSquintLeft","v":0.06105339154601097},
# 		{"k":"MouthDimpleRight","v":0.12425188720226288},
# 		{"k":"BrowInnerUp","v":0.06119655817747116},
# 		{"k":"EyeLookInLeft","v":0.0},
# 		{"k":"MouthPressLeft","v":0.10954130440950394},
# 		{"k":"MouthStretchRight","v":0.09924199432134628},
# 		{"k":"BrowDownLeft","v":0.0},
# 		{"k":"MouthFunnel","v":0.026398103684186937},
# 		{"k":"NoseSneerLeft","v":0.0653044804930687},
# 		{"k":"EyeLookOutLeft","v":0.2591644525527954},
# 		{"k":"EyeLookInRight","v":0.3678726553916931},
# 		{"k":"MouthLowerDownRight","v":0.06102924421429634},
# 		{"k":"BrowOuterUpRight","v":0.0033271661959588529},
# 		{"k":"MouthLeft","v":0.02176971733570099},
# 		{"k":"CheekSquintRight","v":0.07157324254512787},
# 		{"k":"JawOpen","v":0.10355126112699509},
# 		{"k":"EyeBlinkLeft","v":0.0029380139894783499},
# 		{"k":"JawForward","v":0.14734186232089997},
# 		{"k":"MouthPressRight","v":0.11540094763040543},
# 		{"k":"NoseSneerRight","v":0.05933605507016182},
# 		{"k":"JawRight","v":0.0},
# 		{"k":"MouthShrugLower","v":0.2303646206855774},
# 		{"k":"EyeSquintLeft","v":0.11781732738018036},
# 		{"k":"EyeLookOutRight","v":0.0},
# 		{"k":"MouthFrownLeft","v":0.0},
# 		{"k":"CheekPuff","v":0.06076660752296448},
# 		{"k":"MouthStretchLeft","v":0.11452846229076386},
# 		{"k":"TongueOut","v":5.0197301176835299e-11},
# 		{"k":"MouthRollLower","v":0.237720787525177},
# 		{"k":"MouthUpperUpRight","v":0.015751656144857408},
# 		{"k":"MouthShrugUpper","v":0.1125534400343895},
# 		{"k":"EyeSquintRight","v":0.11850234866142273},
# 		{"k":"EyeLookDownLeft","v":0.09258905798196793},
# 		{"k":"MouthSmileLeft","v":0.03695908188819885},
# 		{"k":"EyeWideLeft","v":0.28617817163467409},
# 		{"k":"MouthClose","v":0.08427434414625168},
# 		{"k":"JawLeft","v":0.0317654088139534},
# 		{"k":"MouthDimpleLeft","v":0.12999406456947328},
# 		{"k":"MouthFrownRight","v":0.0},
# 		{"k":"MouthPucker","v":0.07617400586605072},
# 		{"k":"MouthRight","v":0.0},
# 		{"k":"EyeLookUpLeft","v":0.0},
# 		{"k":"BrowDownRight","v":0.0},
# 		{"k":"MouthSmileRight","v":0.01186437252908945},
# 		{"k":"MouthUpperUpLeft","v":0.019432881847023965},
# 		{"k":"BrowOuterUpLeft","v":0.003327207639813423},
# 		{"k":"EyeLookUpRight","v":0.0},
# 		{"k":"EyeLookDownRight","v":0.09135865420103073}
# 	]
# }
class VTSData:
	var has_data := false
	
	var blend_shapes := {}

	var head_rotation := Vector3.ZERO
	var head_position := Vector3.ZERO

	var left_eye_rotation := Vector3.ZERO
	var right_eye_rotation := Vector3.ZERO

	func set_blend_shape(name: String, value: float) -> void:
		name[0] = name[0].to_lower()
		blend_shapes[name] = value

	func set_head_rotation(data: Dictionary) -> void:
		head_rotation = Vector3(data.y, data.x, -data.z)

	func set_head_position(data: Dictionary) -> void:
		head_position = Vector3(data.y, data.x, -data.z)

	func set_left_eye_rotation(data: Dictionary) -> void:
		left_eye_rotation = Vector3(-data.x, -data.y, data.z) / 100.0

	func set_right_eye_rotation(data: Dictionary) -> void:
		right_eye_rotation = Vector3(-data.x, -data.y, data.z) / 100.0
var vts_data := VTSData.new()

var logger := Logger.new(get_name())

var client: PacketPeerUDP
var server_poll_interval: int = 10

var stop_reception := false

var receive_thread: Thread

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	start_receiver()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _perform_reception() -> void:
	while not stop_reception:
		_receive()
		OS.delay_msec(server_poll_interval)

func _receive() -> void:
	client.put_packet(JSON.print({
		"messageType": "iOSTrackingDataRequest", # HMMMM
		"time": 1.0,
		"sentBy": "vpuppr",
		"ports": [
			21412
		]
	}).to_utf8())
	
	if client.get_available_packet_count() < 1:
		return
	if client.get_packet_error() != OK:
		return
	
	var packet := client.get_packet()
	if packet.size() < 1:
		return
	
	var data: Dictionary = parse_json(packet.get_string_from_utf8())

	vts_data.has_data = data.get("FaceFound", false)
	vts_data.set_head_position(data.get("Position", EMPTY_VEC3_DICT))
	vts_data.set_head_rotation(data.get("Rotation", EMPTY_VEC3_DICT))
	vts_data.set_left_eye_rotation(data.get("EyeLeft", EMPTY_VEC3_DICT))
	vts_data.set_right_eye_rotation(data.get("EyeRight", EMPTY_VEC3_DICT))
	for key in data.get("BlendShapes", []):
		vts_data.set_blend_shape(key.k, key.v)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func get_name() -> String:
	return tr("VTUBE_STUDIO_TRACKER_NAME")

func start_receiver() -> void:
	logger.info("Starting receiver")

	var address: String = AM.cm.get_data(ConfigTrackerAddress)
	var port: int = 21412
	
	client = PacketPeerUDP.new()
	client.set_broadcast_enabled(true)
	client.set_dest_address(address, port)
	client.listen(port)

	stop_reception = false

	receive_thread = Thread.new()
	receive_thread.start(self, "_perform_reception")

func stop_receiver() -> void:
	if stop_reception:
		return

	logger.info("Stopping face tracker")

	stop_reception = true

	if receive_thread != null and receive_thread.is_active():
		receive_thread.wait_to_finish()
		receive_thread = null
	
	if client != null and client.is_connected_to_host():
		client.close()
		client = null

func set_offsets() -> void:
	stored_offsets.translation_offset = vts_data.head_position
	stored_offsets.rotation_offset = vts_data.head_rotation
	stored_offsets.left_eye_gaze_offset = vts_data.left_eye_rotation
	stored_offsets.right_eye_gaze_offset = vts_data.right_eye_rotation

func has_data() -> bool:
	return vts_data.has_data

func apply(interpolation_data: InterpolationData, model: PuppetTrait) -> void:
	interpolation_data.bone_translation.target_value = stored_offsets.translation_offset - vts_data.head_position
	interpolation_data.bone_rotation.target_value = stored_offsets.rotation_offset - vts_data.head_rotation

	interpolation_data.left_gaze.target_value = stored_offsets.left_eye_gaze_offset - vts_data.left_eye_rotation
	interpolation_data.right_gaze.target_value = stored_offsets.right_eye_gaze_offset - vts_data.right_eye_rotation

	for key in vts_data.blend_shapes.keys():
		match key:
			"eyeBlinkLeft":
				interpolation_data.right_blink.target_value = 1.0 - vts_data.blend_shapes[key]
			"eyeBlinkRight":
				interpolation_data.left_blink.target_value = 1.0 - vts_data.blend_shapes[key]
			_:
				for mesh_instance in model.skeleton.get_children():
					mesh_instance.set("blend_shapes/%s" % key, vts_data.blend_shapes[key])
