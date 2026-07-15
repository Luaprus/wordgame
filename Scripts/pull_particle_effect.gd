extends Node2D

var particles: Array[Dictionary] = []
var elapsed := 0.0
var duration := 0.42

func play_at(origin: Vector2, cell_size: float, effect_duration := 0.42, seed_value := 2371) -> void:
	position = origin + Vector2.ONE * cell_size * 0.5
	duration = maxf(effect_duration, 0.1)
	elapsed = 0.0
	particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in range(32):
		var angle := TAU * float(index) / 32.0 + rng.randf_range(-0.18, 0.18)
		var speed := rng.randf_range(cell_size * 0.55, cell_size * 1.5)
		particles.append({
			"velocity": Vector2.from_angle(angle) * speed,
			"size": rng.randf_range(3.0, 6.5),
			"delay": rng.randf_range(0.0, 0.08),
			"life": rng.randf_range(0.22, 0.42)
		})
	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		visible = false
		set_process(false)
		particles.clear()
		queue_redraw()
		return
	queue_redraw()

func _draw() -> void:
	for particle: Dictionary in particles:
		var age := elapsed - float(particle.delay)
		if age <= 0.0:
			continue
		var progress := clampf(age / float(particle.life), 0.0, 1.0)
		var offset: Vector2 = particle.velocity * age
		offset.y += 34.0 * age * age
		var alpha := 1.0 - progress
		draw_circle(offset, float(particle.size) * (1.0 - progress * 0.35), Color(1.0, 1.0, 1.0, alpha))
