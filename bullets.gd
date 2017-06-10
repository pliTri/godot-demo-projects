
extends Node2D

# This demo is an example of controling a high number of 2D objects with logic and collision without using scene nodes.
# This technique is a lot more efficient than using instancing and nodes, but requires more programming and is less visual

# Member variables
var BULLET_COUNT = 700
const SPEED_MIN = 20
const SPEED_MAX = 200

var bullets = []
var shape

# Inner classes
class Bullet:
	var pos = Vector2()
	var speed = 1.0
	var angle = PI
	var scale = Vector2(1, 1)
	var body = RID()
	var canvas_item = null

	func _init(canvas_item, shape):
		self.canvas_item = canvas_item

		speed = rand_range(SPEED_MIN, SPEED_MAX)
		body = Physics2DServer.body_create(Physics2DServer.BODY_MODE_KINEMATIC)
		Physics2DServer.body_set_space(body, canvas_item.get_world_2d().get_space())
		Physics2DServer.body_add_shape(body, shape)
		
		pos = Vector2(canvas_item.get_viewport_rect().size * Vector2(randf()*2.0, randf())) # Twice as long
		pos.x += canvas_item.get_viewport_rect().size.x # Start outside
		var mat = Matrix32()
		mat.o = pos
		Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, mat)
		
		angle = (1 + (randf()-0.5)*0.5 )* PI

	func __destroy():
		Physics2DServer.free_rid(body)

	func __process(delta):
		pos += Vector2(cos(angle), -sin(angle)) * speed * delta

		var width = canvas_item.get_viewport_rect().size.x*2.0
		var height = canvas_item.get_viewport_rect().size.y
		# pos.x -= speed*delta
		if pos.x < -30: pos.x += width
		if pos.y < 0: pos.y += height
		elif pos.y > height: pos.y -= height
		var mat = Matrix32()
		mat.o = pos
		
		Physics2DServer.body_set_state(body, Physics2DServer.BODY_STATE_TRANSFORM, mat)
	
	func __draw():
		var t = preload("res://bullet.png")
		var tofs = -t.get_size()*0.5

		canvas_item.draw_set_transform(pos, angle, scale)
		canvas_item.draw_circle(Vector2(0, 0), 5, Color(0, 0, 0, 1))
		canvas_item.draw_texture(t, tofs)

func _draw():
	for b in bullets:
		b.__draw()

func _fixed_process(delta):
	for b in bullets:
		b.__process(delta)
	update()
func _process(delta):

	infolabel.set_text("fps: " + str(floor(1.0/delta*100)/100) 
	+ ", bullets: " + str(BULLET_COUNT) )

	if 1.0/delta > 59:
		var b = Bullet.new(self, shape)
		bullets.append(b)
		BULLET_COUNT += 1
	if 1.0/delta < 58:
		var b = bullets[0]
		bullets.pop_front()
		b.__destroy()
		BULLET_COUNT -= 1


onready var infolabel = get_node("../infolabel")
func _ready():
	shape = Physics2DServer.shape_create(Physics2DServer.SHAPE_CIRCLE)
	Physics2DServer.shape_set_data(shape, 8) # Radius

	for i in range(BULLET_COUNT):
		var b = Bullet.new(self, shape)
		bullets.append(b)
	
	set_fixed_process(true)
	set_process(true)


func _exit_tree():
	for b in bullets:
		b.__destroy()
	
	Physics2DServer.free_rid(shape)
	bullets.clear()
