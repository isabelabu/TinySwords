class_name Player

extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 3
@export_category("Sword")
@export var sword_damage: int = 2
@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30.0
@export var ritual_scene: PackedScene
@export_category("Health")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0,0)
var running: bool = false
var was_running: bool = false
var attacking: bool = false
var cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0

signal meat_collected(value: int)

func _ready():
	GameManager.player = self
	meat_collected.connect(func(value:int):GameManager.meat_counter+=1)

func _process(delta: float) -> void:
	GameManager.player_position = position
	
	#detectar input
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	#atualizar temporizador do ataque
	if attacking:
		cooldown -= delta
		if cooldown <= 0.0:
			attacking = false
			running = false
			animation_player.play("idle")
			
	#tocar animação
	if not attacking:
		if was_running != running:
			if running:
				animation_player.play("walk")
			else:
				animation_player.play("idle")

	#girar sprite
	if not attacking:
		if input_vector.x > 0:
			sprite.flip_h = false
		elif input_vector.x < 0:
			sprite.flip_h = true
			
	#ataque
	if Input.is_action_just_pressed("attack"):
		attack()
		
	#processar dano
	update_hitbox_detection(delta)
	
	#ritual
	update_ritual(delta)
	
	#atualizar barra de progresso
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health

func _physics_process(delta: float) -> void:
	#aplicar velocidade
	var target_velocity = input_vector * speed * 100.0
	if attacking:
		velocity *= 0.25
	
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()
	
	#atualizar running
	was_running = running
	running = not input_vector.is_zero_approx()
		
func attack() -> void:
	if attacking:
		return
	
	animation_player.play("attack_1")
	cooldown = 0.6
	attacking = true
	
func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			
			var dot_product = direction_to_enemy.dot(attack_direction)
			
			if dot_product >= 0.3:
				enemy.damage(sword_damage)



func damage(amount: int) -> void:
	if health <= 0: return
	
	health -= amount
	print(amount, " ", health)
	
	#piscar node
	modulate = Color.DARK_RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self,"modulate",Color.WHITE,0.3)
	
	if health <= 0:
		die()
		
func die():
	GameManager.end_game()
	
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
		
	queue_free()

func update_hitbox_detection(delta: float):
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	
	hitbox_cooldown = 0.5
	
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)

func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	return health

func update_ritual(delta:float):
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	ritual_cooldown = ritual_interval
	
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)
	
