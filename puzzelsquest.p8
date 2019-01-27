pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--game state enums
c_menu_state=0
c_game_state=1
c_lose_state=2
c_win_state=3

--direction constants
c_left=-1
c_right=1

--player sprites
c_player_sprs={
 walk={001,002,003},
 jump=005,
 fall=004,
 wand=006,
 crouch=007,
 crouchwand=022
}
c_life_spr=016
c_dead_player_sprs={
 jump=018,
 fall=018
}
c_happy_player_sprs={049}

--enemy sprites
c_ghost_sprs={
 walk={040},fall=040
 --,010,011,011,
       --010,010,012,012}
}

--level colors
c_lvl_clrs={
 {9,4},
 {12,1},
 {8,2},
 {14,2},
 {7,6},
 {9,1},
 {15,13},
 {3,2}
} 

--used for animation
c_walk_count_max=20

--physics constants
c_jump_vel=-1.8
c_bounce_vel=-1.2
c_gravity=0.2
c_gravity_max=2.0

c_walk_acc=0.2
c_walk_ret=0.4
c_walk_ret_air=0.4
c_walk_ret_wall=0.8
c_walk_max=1.0

c_ghost_dx=0.6
c_ghost_ddx=0

--sprite tile width/height
c_tile_side=8
--map width/height
c_map_side=16
--y coordinate for the
-- copied map
c_copy_map_y=c_map_side*3

--sprite flags
c_solid_flag=0
c_pl1_flag=1
c_key_flag=2
c_goal_flag=3
c_ghost_flag=4
c_spike_flag=6
c_block_flag=7

--enemy types
c_ghost=0
c_shot=4

--music tracks
c_menu_music=00
c_lvl1_music=05
c_lose_music=07
c_win_music=20

--sound effects
c_jump_sfx=0
c_die_sfx=11
c_debug_sfx=12
c_goal_sfx=13
c_walk_sfx=14
c_kill_sfx=15
c_shot_sfx=23
c_warp_sfx=27

c_start_lvl=0
c_last_lvl=2
c_n_lives=3

function lvl_x()
 return lvl_map*c_map_side
end

function 
has_flag(celx,cely,spr_flag)
 sprite=
  mget(celx,
       cely+c_copy_map_y)
 return 
  fget(sprite,spr_flag)
end

function _init() 
 framecount=0
 music(c_menu_music)
 state=c_game_state
 player=0
 dead_player=0
 enemies={};blocks={};
 cauldrons={};key_taken={}
 lvl_map=-1
 n_lives=c_n_lives
 new_level(c_start_lvl)
end

------ game logic ------

function _update()
 framecount+=1
 if state==
 c_lose_state then
  update_lose()
 elseif state==
 c_win_state then
  update_win()
 elseif state==
 c_game_state then
  update_game()
 end
end

function update_lose()
 if btnp(4) then
  _init()
 end
end

function update_win() 
 if btnp(4) then
  _init()
 end
end

function update_game()
 if dead_player!=0 then
  update_dead_player()
 end
 update_cauldrons()
 update_enemies()
 update_blocks()
 if player!=0 then
  update_player()
 end
end

function update_blocks()
 --advance block spawn/
 --despawn animation
 for block in all(blocks) do
  if block.despawn then
   block.curr_anim=
        block.curr_anim+1
   if block.curr_anim>2 then
    del(blocks,block)
   end
  else
   if block.curr_anim>0 then
    block.curr_anim=
        block.curr_anim-1
   end
  end
 end
end

function update_dead_player()
 gravity(dead_player)
 if dead_player.y>
    c_tile_side*c_map_side+10
 then
  lose_life()
 end
end

function lose_life()
 dead_player=0
 if n_lives>=1 then
  --n_lives-=1
  restart_level()
 else
  game_over()
 end
end

function game_over()
 state=c_lose_state
 music(c_lose_music)
end

function update_enemies()
 for enemy in all(enemies) do
  if enemy.id==c_bubble then
   update_bubble(enemy)
  else
   update_enemy(enemy)
  end
 end
end

function update_enemy(enemy)
 if enemy.enemy_type==
 c_ghost then
  update_ghost(enemy)
 end
end

function 
update_ghost(ghost)

 local solidleft=
     is_solid_flr_lft(ghost)
 local solidright=
     is_solid_flr_rgt(ghost)
 if (not solidleft) and
    (not solidright) then
  ghost.in_air=true
  ghost.walk_count=0
  ghost.olddx=ghost.dx
  ghost.dx=0
 elseif not solidleft
     or not solidright
     or is_solid_sideways(ghost)
 then
  ghost.walk_count=0
  ghost.dir*=-1
  ghost.dx*=-1
 elseif ghost.in_air and
    (solidleft or solidright)
 then --back on ground
  ghost.dx=c_ghost_dx
  ghost.in_air=false
 end
 ghost.x+=ghost.dx
 advance_walk_count(ghost)
 gravity(ghost)
end

function shoot_left(x,y)
 sfx(c_shot_sfx)
 add(enemies,
     create_shot(x,y,
       -2-rnd(1),rnd(0.2)-0.1,
       c_shot_left_sprs))
end

function shoot_up(x,y)
 sfx(c_shot_sfx)
 add(enemies,
     create_shot(x,y,
       rnd(0.4)-0.2,-1-rnd(0.5),
       c_shot_up_sprs))
end

function 
create_shot(x,y,dx,dy,sprs)
 return 
  {x=x,
   y=y,
   dx=dx,
   dy=dy,
   walk_count=0,
   in_air=false,
   sprs=sprs,
   enemy_type=c_shot}
end

function update_shot(shot)
 advance_walk_count(shot)
 shot.x+=shot.dx
 shot.y+=shot.dy
 if shot.x<-10 or
    shot.y<-10 then
  del(enemies,shot)
 end
end
function update_player()
 if not player.wanding then
  control_player(player)
 else
  player.wandanim =
     player.wandanim-1
  if player.wandanim==0 then
   player.wanding=false
  end
 end
 gravity(player)
 walk_player(player)
 wall_retard(player)
 check_collisions(player)
end

function control_player(actor)
 if btn(0,actor.no) then
  move_left(actor)
 elseif btn(1,actor.no) then
  move_right(actor)
 else
	 stop_walking(actor)
 end
 if btnp(2,actor.no) then
  jump(actor)
 end
 if btn(3,actor.no) then
  crouch(actor)
 else
  stopcrouch(actor)
 end
 if btnp(4,actor.no) then
  wand(actor)
 end
end

function move_left(actor)
 actor.dir=c_left
 move_walking(actor)
end

function move_right(actor)
 actor.dir=c_right
 move_walking(actor)
end

function move_walking(actor)
 actor.is_walking=true
 advance_walk_count(actor)
 play_walk_sound(actor)
end

-- used primarily 
-- for animations
function 
advance_walk_count(actor)
 actor.walk_count=
  (actor.walk_count+1)
   %c_walk_count_max
end

function play_walk_sound(actor)
 if not actor.in_air and 
 flr(actor.walk_count%10)==0 
 then
  sfx(c_walk_sfx)
 end
end

function stop_walking(actor)
 actor.is_walking=false
 actor.walk_count=0
end

function jump(actor)
 if not actor.in_air then
  sfx(c_jump_sfx)
  actor.dy=c_jump_vel
 end
end

function crouch(actor)
 if not actor.in_air 
    and not actor.walking
    then
  actor.crouching=true
 end
end

function stopcrouch(actor)
 actor.crouching=false
end
function gravity(actor)
 if actor.in_air then
  actor.oldx=actor.x
  actor.y+=actor.dy
  actor.dy=
   min(actor.dy+c_gravity,
       actor.ddy_max)
 end
end

function walk_player(actor)
 if actor.is_walking then
  actor.ddx=c_walk_acc
  accelerate(actor)
 else
  if actor.in_air then
   actor.ddx=c_walk_ret_air
  else
   actor.ddx=c_walk_ret
  end
  retard(actor)
 end
 
 actor.oldx=actor.x
 actor.x+=actor.dx
end

function accelerate(actor)
 if actor.dir==c_left then
  actor.dx=
   max(actor.dx-actor.ddx,
       -c_walk_max)
 else
  actor.dx=
   min(actor.dx+actor.ddx,
       c_walk_max)
 end
end

function retard(actor)
 if actor.dir==c_left then
  actor.dx=
   min(actor.dx+actor.ddx,0)
 else
  actor.dx=
   max(actor.dx-actor.ddx,0)
 end
end

function 
wall_retard(actor)
 if is_solid_sideways(actor)
 then
  actor.ddx=c_walk_ret_wall
  retard(actor)
 end
end

--todo maybe move to collisions
function 
death_collisions(actor)
 should_die=
  enemy_collisions(actor)
  or pit_collisions(actor)
  or spike_collisions(actor)
 if should_die then
  die()
 end
end

function die()
 sfx(c_die_sfx)
 dead_player=
  create_dead_player(
   player.x,player.y)
 dead_player.dy=-2
 player=0
end

function 
create_dead_player(x,y)
 return
  {x=x,y=y,
   dx=0,dy=0,
   ddy_max=4,
   in_air=true,
   dir=c_right,
   sprs=c_dead_player_sprs}
end
-->8
--- new level ---
function restart_level()
 new_level(lvl_map)
end 

function next_level()
 if lvl_map==c_last_lvl then
  state=c_win_state
 else
  new_level(lvl_map+1)
 end
end

function new_level(lvl_map_no)
 clean_ents()
 lvl_map=lvl_map_no
 copy_map()
 create_ents()
end

--this hack copies the level's
--part of the map to another
--part of the map, so that 
--things removed from the map
--will not be permanently
--removed.
function copy_map()
 for celx=0,c_map_side-1 do
  for cely=0,c_map_side-1 do
   copy_tile(celx,cely)
  end
 end
end

function copy_tile(celx,cely)
 mset(celx,cely+c_copy_map_y,
  mget(celx+lvl_x(),cely))
end

--ents is short for entities
function clean_ents()
 player=0
 enemies={}
 particles={}
 cauldrons={}
 blocks={}
 goal=nil
end

function create_ents()
 for celx=0,c_map_side-1 do
  for cely=0,c_map_side-1 do
   look_for_ents(celx,cely)
  end
 end
end

function 
look_for_ents(celx,cely)
 look_for_ent(is_player_spr,
              create_player,
              celx,cely)
 look_for_ent(is_ghost_spr,
              create_ghost,
              celx,cely)
 look_for_ent(is_block_spr,
              create_block,
              celx,cely)
 look_for_ent(is_goal_spr,
              create_goal,
              celx,cely)
 look_for_ent(is_worm_spr,
              create_worm,
              celx,cely)
 look_for_ent(is_cauldron_spr,
              create_cauldron,
              celx,cely)
 --look_for_lives(celx,cely)
end

function look_for_ent(
																isfun,
                createfun,
                celx,cely)
 --fun with 2nd order functions!
 if isfun(celx,cely)
 then
  createfun(celx*c_tile_side,
            cely*c_tile_side)
  remove_spr(celx,cely)
 end
end

function create_block(blockx,
                      blocky)
 add_block(blockx/8,blocky/8)
end

function 
is_player_spr(celx,cely)
 return has_flag(celx,cely,
                 c_pl1_flag)
end

function 
create_player(x,y)
 player=
  {x=x,y=y,
   oldx=x,
   dx=0,dy=0,
   ddx=0,
   ddy_max=c_gravity_max,
   is_walking=false,
   in_air=false,
   crouching=false,
   wandanim=0,
   dir=c_right,
   walk_count=0,
   sprs=c_player_sprs}
end

function is_goal_spr(celx,cely)
 return has_flag(celx,cely,
                 c_goal_flag)
end

function create_goal(x,y)
 goal={x=x,y=y,
       open=false,
       closed_spr=049,
       open_spr=050}
 local key=key_taken[lvl_map+1]
 if key!=nil
 then
  goal.open=true
  remove_key(key.x,key.y)
 end
end

function remove_key()

end

function 
is_ghost_spr(celx,cely)
 return has_flag(celx,cely,
                 c_ghost_flag)
end

function create_ghost(x,y)
 add(enemies,
     {x=x,y=y,
      dx=c_ghost_dx,
      ddx=c_ghost_ddx,
      dy=0,
      ddy_max=c_gravity_max,
      dir=c_right,
      is_walking=true,
      in_air=false,
      wandanim=0,
      walk_count=0,
      sprs=c_ghost_sprs,
      enemy_type=c_ghost})
end

function is_block_spr(celx,cely)
	return has_flag(celx,cely,
	                c_block_flag)
end

function remove_spr(celx,cely)
 mset(celx,cely+c_copy_map_y,
      000)
end
-->8
--- collision detection ---
function 
check_collisions(actor)
 key_collisions(actor)
 solid_collisions(actor)
 death_collisions(actor)
 if actor!=0 then
  --i.e. not dead
  goal_collisions(actor)
 end
end

function goal_collisions(actor)
 if goal.open
    and is_at_goal(actor) then
  next_level()
 end
end

function is_at_goal(actor)
 return rects_intersect(
           actor.x,actor.x+7,
           actor.y,actor.y+2,
           goal.x+2,goal.x+5,
           goal.y+2,goal.y+5)
end

function is_goal_spr(celx,cely)
 return has_flag(celx,cely,
                 c_goal_flag)
end

function key_collisions(actor)
 for x=actor.x,actor.x+7 do
  for y=actor.y,actor.y+7 do
   get_key(x,y)
  end
 end
end

function get_key(x,y)
 if is_point_key(x,y) then
  key_taken[lvl_map+1]={x=x,y=y}
  remove_key(x,y)
  goal.open=true
  sfx(c_life_sfx)
 end
end

function is_point_key(x,y)
 local celx=flr(x/c_tile_side)
 local cely=flr(y/c_tile_side)
 
 return 
  has_flag(celx,cely,
           c_key_flag)
end

function remove_key(x,y)
 local celx=
  flr(x/c_tile_side)
 local cely=
  flr(y/c_tile_side)
 remove_spr(celx,cely)
end

function warp_collisions(actor)
 if lvl_map==1 and 
 rects_intersect(
      actor.x, actor.x+7,
      actor.y, actor.y+7,
      122,126,
      122,126) then
  sfx(c_warp_sfx)
  new_level(6)
 end 
end

function 
enemy_collisions(actor)
 for enemy in all(enemies) do
  if death_collision(actor,
                      enemy)
  then
   return true
  end
 end
 return false
end

function 
death_collision(actor,enemy)
 return
  rects_intersect(
   actor.x, actor.x+7,
   actor.y, actor.y+7,
   enemy.x+1,enemy.x+6,
   enemy.y+2,enemy.y+6)
end

function rects_intersect(
  a_x1,a_x2, a_y1,a_y2,
  b_x1,b_x2, b_y1,b_y2)
 return
  range_intersect(
   a_x1,a_x2,
   b_x1,b_x2)
  and
  range_intersect(
   a_y1,a_y2,
   b_y1,b_y2)
end

function range_intersect(
				min0,max0, min1,max1)
 return
  max0>=min1
  and 
  min0<=max1 
end

function pit_collisions(actor)
 if actor.y>
    c_tile_side*c_map_side 
 then
  return true
 end
 return false
end

function 
spike_collisions(actor)
 return
  is_spike_beneath(actor) 
  or is_spike_above(actor)
end

function 
is_spike_beneath(actor)
 return is_spike_se(actor)
     or is_spike_sw(actor)
end

function 
is_spike_se(actor)
 local x=actor.x+c_tile_side-2
 local y=actor.y+c_tile_side-2
 return is_point_spike(x,y)
end

function 
is_spike_sw(actor)
 local x=actor.x
 local y=actor.y+c_tile_side-2
 return is_point_spike(x,y)
end

function
is_spike_flr_rgt(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y+c_tile_side
 return is_point_spike(x,y)
end

function 
is_spike_flr_lft(actor)
 local x=actor.x
 local y=actor.y+c_tile_side
 return is_point_spike(x,y)
end

function 
is_spike_above(actor)
 return is_spike_ne(actor)
     or is_spike_nw(actor)
end

function 
is_spike_ne(actor)
 local x=actor.x+1
 local y=actor.y+1
 return is_point_spike(x,y)
end

function 
is_spike_nw(actor)
 local x=actor.x+1
 local y=actor.y+c_tile_side-2
 return is_point_spike(x,y)
end

function is_point_spike(x,y)
 local cel_x=flr(x/c_tile_side)
 local cel_y=flr(y/c_tile_side)
 
 return is_spike(cel_x, cel_y)
end

function is_spike(celx,cely)
 return has_flag(celx,cely,
                 c_spike_flag)
end

function is_blocked(celx,cely)
--first check the map
 if has_flag(celx,cely,
             c_solid_flag) then
  return true
 end
 for enemy in all(enemies) do
  if rects_intersect(
        celx*8,(celx*8)+7,
        cely*8,(cely*8)+7,
        enemy.x,enemy.x+7,
        enemy.y,enemy.y+7)
  then
   return true
  end
 end
end

function all_ents()
 return enemies
end

--- end collision detection ---

-->8
--- solid collisions ---
function 
solid_collisions(actor)
 if is_solid_sideways(actor) 
 then
  push_sideways(actor)
 end
 if is_solid_floor(actor) and 
    actor.dy>=0 then
  push_up(actor)
  actor.in_air=false
 else
  actor.in_air=true
 end
 if is_solid_above(actor) then
  
  hitblockabove(actor)
  push_down(actor)
 end
end

function hitblockabove(actor)
 local middle=getmiddle(actor)
 local abovey=actor.y-4
 --the above is an estimate
 local cell=getcell(middle,
                    abovey)
 local block=getblockat(cell.x,
                        cell.y)
 if block != nil then
  crush(block)
 end
end
function getmiddle(actor)
 if actor.dir==c_right then
  return actor.x+3
 else
  return actor.x+4
 end
end
function getcell(x,y)
 return {x=flr(x/8),y=flr(y/8)}
end

function
is_solid_sideways(actor)
 return is_solid_left(actor)
     or is_solid_right(actor)
end

function is_solid_left(actor)
 return
  is_solid_nw(actor) or
  is_solid_sw(actor)
end

function is_solid_right(actor)
 return 
  is_solid_ne(actor) or
  is_solid_se(actor)
end

function is_solid_floor(actor)
 return
  is_solid_flr_lft(actor) or
  is_solid_flr_rgt(actor)
end

function is_solid_above(actor)
 return
  is_solid_nw(actor) or
  is_solid_ne(actor)
end

function is_solid_nw(actor)
 local x=actor.x
 local y=actor.y
 --add one pixel 'slack'
 return is_point_solid(x+1,y)
end

function is_solid_ne(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y
 return is_point_solid(x-1,y)
end

function is_solid_se(actor)
 local x=actor.x+c_tile_side-1
 local y=actor.y+c_tile_side-2
 return is_point_solid(x,y)
end

function is_solid_sw(actor)
 local x=actor.x
 local y=actor.y+c_tile_side-2
 return is_point_solid(x,y)
end

function 
is_solid_flr_rgt(actor)
 local x=actor.x+c_tile_side-2
 local y=actor.y+c_tile_side
 return is_point_solid(x,y)
end

function 
is_solid_flr_lft(actor)
 local x=actor.x+1
 local y=actor.y+c_tile_side
 return is_point_solid(x,y)
end

function is_point_solid(x,y)
 local cel_x=flr(x/c_tile_side)
 local cel_y=flr(y/c_tile_side)
 
 return is_solid(cel_x, cel_y)
end

function is_solid(celx,cely)
 return
  has_flag(celx,cely,
           c_solid_flag)
   or
  has_block(celx,cely)
   or
  has_cauldron(celx,cely)
end

function has_block(celx, cely)
 for block in all(blocks) do
  if celx==block.celx
     and
     cely==block.cely then
   return true
  end
 end
 return false
end

function push_sideways(actor)
 actor.x=actor.oldx
end

function push_up(actor)
 local tile_side=8
 local new_y=
  flr(actor.y/tile_side)
  * tile_side
 actor.y=new_y
 actor.dy=0
end

function push_down(actor)
 local tile_side=8
 local new_y=
  (flr(actor.y/tile_side)+1)
  * tile_side
 actor.y=new_y
 actor.dy=0 
end
--- end solid collisions ---

-->8
------ graphics ------

function _draw()
 cls()
 if state==c_menu_state then
  draw_menu()
 elseif state==c_game_state
 then
  draw_game()
 elseif 
 state==c_lose_state then
  draw_lose()
 elseif state==c_win_state then
  draw_win()
 end
end

function draw_menu()
 print(
  "the legend of",
  0,23,3)
end

function draw_win()
 print(
  "conglaturation! 🐱",
  23,32,7)
end

function draw_game()
 draw_map()
 draw_goal()
 if player~=0 then
  draw_actor(player)
 end
 if dead_player~=0 then
  draw_actor(dead_player)
 end
 draw_enemies()
 draw_cauldrons()
 draw_particles()
 draw_lives()
 draw_blocks()

end

function draw_cauldrons()
 for cauldron in all(cauldrons)
 do
  local sprite=
      cauldron.sprs[1]+
          cauldron.curr_anim
  spr(sprite,cauldron.x,
             cauldron.y)
 end
end

function draw_goal()
 if goal.open then
  spr(goal.open_spr,
      goal.x,goal.y)
 else
  spr(goal.closed_spr,
      goal.x,goal.y)
 end
end  

function draw_blocks()
 for block in all(blocks) do
  draw_block(block)
 end
end

function draw_block(block)
 local sprite=0
 if block.cracked then
  sprite=032+block.curr_anim
 else
  sprite=033+block.curr_anim
 end
 spr(sprite,block.celx*8,
            block.cely*8)
end

function draw_map()
 --pal(c_lvl_clrs[1][1],
 --    c_lvl_clrs[lvl_map+1][1])
 --pal(c_lvl_clrs[1][2],
 --    c_lvl_clrs[lvl_map+1][2])
 map(0,c_copy_map_y,
     0,0,
     c_map_side,c_map_side)
 pal()
end

function draw_enemies()
 for enemy in all(enemies) do
  if enemy.id==c_bubble then
   draw_bubble(enemy)
  else
   draw_actor(enemy)
  end
 end
end

function draw_bubble(bubble)
 local sprite=0
 if bubble.burstanim>0 then
  sprite=bubble.sprs[2]
 else
  sprite=bubble.sprs[1]
 end
 spr(sprite,
     bubble.x,bubble.y)
end

function draw_actor(actor)
 local flip_sprite=
  actor.dir==c_left
 spr(get_actor_spr(actor),
     actor.x,
     actor.y,
     1,1,flip_sprite)
end

function get_actor_spr(actor)
 if actor.wandanim!=0 and
    actor.crouching then
  return actor.sprs.crouchwand
 elseif actor.wandanim!=nil
     and actor.wandanim!=0 then
  return actor.sprs.wand
 elseif actor.in_air then
  return get_air_spr(actor)
 elseif actor.crouching then
  return actor.sprs.crouch
 else
  return get_walk_spr(actor)
 end
end

function get_air_spr(actor)
 if actor.dy<0 then
  return actor.sprs.jump
 else
  return actor.sprs.fall
 end
end

function get_walk_spr(actor)
 local spr_index=
  flr(actor.walk_count
      /(c_walk_count_max
        /#actor.sprs.walk))
  +1

 return 
  actor.sprs.walk[spr_index]
end

function draw_particles()
 foreach(particles,
         draw_particle)
end

function 
draw_particle(particle)
 circfill(particle.x,
          particle.y,
          particle.width,
          particle.clr)
end

function draw_lives()
 y=0
 for i=1,n_lives do
  x=8*(i-1)
  spr(c_life_spr,x,y)
 end
end


-->8
--block logic

function wand(actor)
 --need to figure out what
 --is the closest cell next to
 --player
 actor.wanding=true
 actor.wandanim=4 --4 frames
	if actor.dir==c_left then
	 xmod = -1
	else
	 if (actor.x)%8<2 then
	  --right at the line
	  xmod=1 else xmod=2 end
	end
	if actor.crouching then
	 ymod=1
	else ymod=0	end
	block_celx=
	    flr((actor.x/8)+xmod)
	block_cely=
	    flr(((actor.y+4)/8)+ymod)
	switch_block(block_celx,
														block_cely)
end

function switch_block(
															block_celx,
															block_cely)
	for block in all(blocks) do
	 if block_celx==block.celx and
	    block_cely==block.cely then
	  block.despawn=true
	  return
	 end
	end
	if not is_blocked(block_celx,
	                  block_cely)
	then
	 add_block(block_celx,
	           block_cely)
	end
end

function add_block(block_celx,
                   block_cely)
 add(blocks, {celx=block_celx,
 	 											cely=block_cely,
 	 											curr_anim=2,
 	 											despawn=false,
 	 											cracked=false})
end

function crush(block)
 if block.cracked then
  switch_block(block.celx,
               block.cely)
 else
  block.cracked=true
 end
end

function getblockat(celx,cely)
 for block in all(blocks) do
  if celx==block.celx and
     cely==block.cely then
   return block
  end
 end
 return nil
end
-->8
--new enemies

function is_worm_spr(sprite)
 return sprite==042
end

function create_worm(x,y)
 add(enemies,{x=x,y=y,
              walking=true})
end
c_cauldron_spr=057
function is_cauldron_spr(celx,
                         cely)
 return has_number(celx,cely,
               c_cauldron_spr)
end
function create_cauldron(x,y)
 add(cauldrons,
     {x=x,y=y,
 					curr_anim=0,
 					sprs={c_cauldron_spr}})
 remove_spr(x,y)
end

function update_cauldrons()
 for cauldron in all(cauldrons)
 do
  if framecount%(3*30)==0 then
   spawnbubble(cauldron.x,
               cauldron.y)
  end
  if framecount%20==0 then
   if cauldron.curr_anim==0 then
    cauldron.curr_anim=1
   else
    cauldron.curr_anim=0
   end
  end
 end
end

c_bubble=20
function spawnbubble(x,y)
 add(enemies,{x=x,y=y-1,
              id=c_bubble,
              sprs={059,060},
              dy=-0.3,
              burstanim=0})
end
function update_bubble(bubble)
 if (bubble.y-8)<0 then
  del(enemies,bubble)
 end
 if bubble.burstanim>0 then
  if bubble.burstanim==1 then
   del(enemies,bubble)
   return
  end
  bubble.burstanim-=1
 end
 if is_solid_above(bubble) then
  hitblockabove(bubble)
  bubble.burstanim=5
  bubble.dy=0
 end
 bubble.y+=bubble.dy
end
function has_cauldron(celx,cely)
 for cauldron in all(cauldrons)
 do
  local ccelx=flr(cauldron.x/8)
  local ccely=flr(cauldron.y/8)
  if ccelx==celx and
     ccely==cely then
   return true
  end
 end
 return false
end

--todo most stuff to do with
--cauldrons

function 
has_number(celx,cely,number)
 sprite=
  mget(celx,
       cely+c_copy_map_y)
 return sprite==number
end
__gfx__
00000000000000000111000000000000010000000000000000000000000000000040400004040000000000000440004400000000000000000000000000000000
00000000011100001011100011110000011100000011000000011110000000000044440004444000040400000444040000000000000000000000000000000000
007007001011100000111100001110000011100001111000011110071111100004a4a4404a4a44040444400044a4004000000000000000000000000000000000
0007700000111100001a1a000011110000111100101a1a00011110001011110004444400444440404a4a44044000000400000000000000000000000000000000
00077000001a1a0001111110001a1a00001111000011110001a1a000001111000004400400440040444440400000444000000000000000000000000000000000
00700700011111101d11111d01111110011a1a1001111110011111100111a1a0000ff00400ff4004000440400000000000000000000000000000000000000000
000000001d11111d11d11dd11d11111d1d11111d1d11111d1d11111d1d11111d0004f440004f4444004ff0040000000000000000000000000000000000000000
0000000011d11dd10000000011d11dd111d11dd111d11dd111d11dd111d11dd10004040404040404004444440404040400000000000000000000000000000000
00000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000f000000ff00000000000000000000000000000000000000000
0000000000af00f000111000000000000000000000000000001111000000000000660f0000000f000000000f0000000000000000000000000000000000000000
0000000005400400001111000000000000000000000000000111101000000000568600f0000000ff0000000f0050505000505050005050500050505000000000
000000000540040000a11a000000000000000000000000000111110100000000006660f00006660f0006660f050d5d50050d5d50050d5d50050d5d5000000000
00000000dd11dd1111111110000000000000000000000000011a1a1100000000000666000568666f0568666f0505dd500505dd500505dd500505dd5000000000
00000000111111001d11111d000000000000000000000000d11111d7000000000005050000666660006666600505000505050005050500050505000500000000
000000000111111101d11dd10000000000000000000000001d111d10000000000000000000f000f0000f0f005005000550050005500500055005000500000000
06a95a6006a9aa600000000000000000444445445555555555555555000000000007770000000000000000000000000000000000000000000000000000000000
6a959a966a9a9a960700007000070000444445444544444444444444000000000077777000000000000000000000000000000000000000000000000000000000
599955aaa999a9aa0070770000070000555555554545444444444445000000000778778700000000000000000000000000000000000000000000000000000000
955a995a9a9a999a007a70000007a770454444444544444444444444000000000758758700000000000000000000000000000000000000b30000000000000000
a9a559a9a9a9a9a90007a700077a70004544444455555555555555550000000007777777000000000000000000000000000b3000000003300000000000000000
a599959aaa999a9a007707000000700055555555444444544444444400000000077555570000000000000000003b3000003b3b000000bb000000000000000000
69a955a669a9a9a6070000700000700044444544444454545444444400000000075555700000000000bb33b0003b3b0000300b00000030000000000000000000
06559a6006aa9a600000000000000000444445444444445444444444000000007777770000000000b3bb33b30b000b300b000030000b30000000000000000000
0000000000dddd0000dddd0000000900009a90000000099000000000000000000450054000000b0000b000000000000000000000000000000000000000000000
070000700d2424d00d0000d000090090000090000009009000000000000000000445544013b3333113333b310003300000000000000000000000000000000000
00707700d424242d4400000d00099990000a900000009990000000000000000045a44a54d1333311d13333110030030000300300000000000000000000000000
007a7000d424252d4240000d0000900000009000000099000000000000000000445445440111111001111110030b003003000030000000000000000000000000
0007a700d424505d4240000d0909000000009000000990000000000000000000444ee44411111111111111110300003000000000000000000000000000000000
00770700d424252d4240000d9a900000009999900000000000000000000000000554455011d1111111d111110030030000000000000000000000000000000000
07000070d424242d4240000d90a90000009a0a9000000000000000000000000000444400d1dd1111d1dd11110003300000300300000000000000000000000000
00000000ddddddddd44ddddd0990000000099900000000000000000000000000000000000d1111100d1111100000000003000030000000000000000000000000
__gff__
0002020000000000000000000000000000000000000000000000000000000000808001010101010010000000000000000008080004000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2525252525252525252525252525252524242424242424242424242424242424252526252625262526252625262526250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2510000000000000000000000000002524000000000000000000000000000024250000000000000000000000000000260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2510001000000000000000000000002524000000000000000000000000000024260000310000000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524000000000000000000000000000024250000000000000000000000000000260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524242424242400000000000000000024260000000000000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524212121212121210000000000000024250000003900000000000000000000260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524002128002121210000000000000024262424242421242421242424240000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524312121210028210000000000000024250000000000000000000000000000260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524242424242424242424242121212424260000000000000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524000000000000000000000000000024252121242421242421242421212421260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2531000000000028000000000000002524010000000000280000000000000024260000000000000000240000282400250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2526252625262526252621212125262524242424240000240000000000000024250000000000000000242121212400260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000000000002524000000210000000000000000000024262424240000000000240028000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000212121000000000000002524000000240000000000000000000024250000000000000000242121210000260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500010000213421000000000000002524340000240000000000280039000024260001000039000039240000003400250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525252525252525252525252524242424242424242424242424242424252625262526252625262526252625260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000029040000200003000040000300001000000340500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344

