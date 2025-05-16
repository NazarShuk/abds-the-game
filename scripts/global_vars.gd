extends Node

const api_url = "https://script.google.com/macros/s/AKfycbwwbWjvbwCQxZcnXEikI96x1sYPKr6lxIpzs0IFw4M0WolIjuSBZbG36cQVDBnQPDSK/exec"

var steam_error : String
var steam_error_code : int
var firstTime = true
var is_fullscreen = false
var non_steam
var playbacks = []

var is_bossfight = false

var did_show_parry_tip = false

var menu_music_duration = 0
var did_show_disclaimer = false

var books_collected = 0
var deaths = 0
var competitive_team_won = ""

var leahy_time_rank = "d"

var current_skin = Node.new()

var game_scene = null

var is_steam_peer = false
