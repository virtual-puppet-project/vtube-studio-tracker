extends TrackingBackendTrait

## https://github.com/DenchiSoft/VTubeStudio
## https://github.com/Inochi2D/facetrack-d/blob/main/source/ft/adaptors/vtsproto.d

var logger := Logger.new(get_name())

var client: PacketPeerUDP
var server_poll_interval: int = 100

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
		"messsageType": "iOSTrackingDataRequest",
		"time": 1.0,
		"sentBy": "asdf",
		"ports": [
			21412
		]
	}).to_utf8())
	if client.get_available_packet_count() < 1:
		return
	if client.get_packet_error() != OK:
		logger.error("Last packet had an error: %d" % client.get_packet_error())
		return
	
	var packet := client.get_packet()
	if packet.size() < 1:
		return

	print(packet.get_string_from_utf8())

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func get_name() -> String:
	return "VTubeStudio"

func start_receiver() -> void:
	# TODO many of these values are stubs

	logger.info("Starting receiver")

	var address: String = ""
	var port: int = 21412

	client = PacketPeerUDP.new()
	client.connect_to_host(address, port)

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

	if client.is_connected_to_host():
		client.close()
		client = null

func set_offsets() -> void:
	pass

func has_data() -> bool:
	return true # TODO stub

func apply(interpolation_data: InterpolationData, _model: PuppetTrait) -> void:
	pass
