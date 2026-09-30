extends Node
## Autoload: Audio. Owns the music player and a small SFX pool.
## Callers request a cue; this node chooses the bus and a free voice.

enum Cue { PET, FEED, GREW, CORRECT, WRONG, QUIZ_SUCCESS, SUSHI }

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const VOICE_COUNT := 9

@export var music: AudioStream
@export var pet: AudioStream
@export var feed: AudioStream
@export var grew: AudioStream
@export var correct: AudioStream
@export var wrong: AudioStream
@export var quiz_success: AudioStream
@export var sushi: AudioStream
@export_range(-24.0, 0.0) var music_volume_db := -8.0

var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	_music.volume_db = music_volume_db
	_music.stream = music
	add_child(_music)
	if music != null:
		_music.play()

	for _i in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS_SFX
		add_child(voice)
		_voices.append(voice)


func play(cue: Cue, vary_pitch := false) -> void:
	var stream := _stream_for(cue)
	if stream == null:
		return
	var voice := _free_voice()
	if voice == null:
		return
	voice.stream = stream
	voice.pitch_scale = randf_range(0.94, 1.06) if vary_pitch else 1.0
	voice.play()


func _stream_for(cue: Cue) -> AudioStream:
	match cue:
		Cue.PET:
			return pet
		Cue.FEED:
			return feed
		Cue.GREW:
			return grew
		Cue.CORRECT:
			return correct
		Cue.WRONG:
			return wrong
		Cue.QUIZ_SUCCESS:
			return quiz_success
		Cue.SUSHI:
			return sushi
		_:
			return null


func _free_voice() -> AudioStreamPlayer:
	for voice in _voices:
		if not voice.playing:
			return voice
	return null
