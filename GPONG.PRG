/*
 * GALAX PONG
 *
 * Copyright 2020 Miguel Company (UAMike)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

program GPONG;

const
    PATH_USER = "UAMIKE";
    PATH_PROG = "GPONG";

    PLAYER_STATE_DEAD = -1;
    PLAYER_STATE_MOVING = 1;
    PLAYER_STATE_DYING = 2;

    MAX_VELOCITY = 6;
    SHOOT_CADENCE = 100;

    GRAPH_BACKGROUND = 1;
    PLAYER_GRAPH = 13;

    MIN_Y = 16;
    MAX_Y = 360 - 16;

    PLAYER_INVULNERABLE_TIME = 150;

global
    struct player_t[1]
        int pid;
        int state;
        int lifes;
        int vel;
        int next_shoot_time;
        int missile_id;
    end =
    0, PLAYER_STATE_DEAD, 3, 0, 0, 0,
    0, PLAYER_STATE_DEAD, 3, 0, 0, 0;

    int g_file;

local
    int n;

begin
    load_resources();
    config_game();
    // main_menu();

    quick_test();

    debug;
    exit("Fin", 0);
end

function quick_test()
begin
    player(0, 16, 180, 0, -90000);
    keyb_input(0, _q, _a, _x);
    simple_sprite(275, 175, min_int+1, g_file, 30);

    player(1, 640-16, 180, 1, -90000);
    keyb_input(1, _p, _l, _m);
    simple_sprite(365, 175, min_int+1, g_file, 30);

    // simple_sprite(16, 100, -1, g_file, 5);
    // simple_sprite(160, 260, -1, g_file, 5);

    enemy_fire(0, 220, 180, -1, 16, 17);
    frame(fps * 100);
    enemy_fire(0, 220, 180, -1, 16, 17);

    loop frame; end

end

/////////////////
//// CONFIGURATION
/////////////////
function load_resources()
begin
    g_file = load_fpg(path_resolve("GPONG.FPG"));
end

function config_game()
begin
    set_mode(m640x400);
    set_fps(24, 0);
    background(g_file, GRAPH_BACKGROUND);
end

process background(file, graph)
begin
    x = 320; y = 200; z = min_int + 1;
    loop frame; end
end

/////////////////
//// PLAYER AND CONTROL
/////////////////
process player(n, x, y, flags, angle)
private
    id_collision;
begin
    player_t[n].pid = id;
    player_t[n].state = PLAYER_STATE_MOVING;
    player_t[n].lifes = 0;    // TODO: initialize to MAX_LIFES in single player mode
    player_t[n].vel = 0;
    player_t[n].next_shoot_time = 0;
    player_t[n].missile_id = 0;
    player_invulnerable(id);

    file = g_file;

    while (player_t[n].state != PLAYER_STATE_DEAD)
        switch (player_t[n].state)
            case PLAYER_STATE_MOVING:
                y += player_t[n].vel;
                y = clamp (y, MIN_Y, MAX_Y);
                graph = PLAYER_GRAPH;
                frame;

                // Check collisions and handle life
                if (flags < 4)
                    id_collision = collision (TYPE enemy);
                    if (id_collision == 0)
                        id_collision = collision (TYPE enemy_fire);
                    end

                    if(id_collision)
                        player_starts_dying(n);
                    end
                end
            end

            case PLAYER_STATE_DYING:
                explosion(x, y, 100);
                player_finished_dying(n);
            end

            default:
                frame;
            end
        end
    end
end

process player_invulnerable(player_id)
private end_time;
begin
    player_id.flags += 4;
    end_time = timer[0] + PLAYER_INVULNERABLE_TIME;
    while(timer[0] < end_time)
        frame;
    end
    player_id.flags -= 4;
end

function player_starts_dying(n)
begin
    player_t[n].vel = 0;
    player_t[n].state = PLAYER_STATE_DYING;

    // TODO: Decrement lifes in single player mode
end

function player_finished_dying(n)
begin
    player_t[n].state = PLAYER_STATE_MOVING;
    player_invulnerable(player_t[n].pid);

    // TODO: Player may go to PLAYER_STATE_DEAD in single player mode
end

function try_to_shoot(n)
begin
    if ( (timer[0] >= player_t[n].next_shoot_time) or
         (player_t[n].missile_id == 0) )
        player_t[n].next_shoot_time = timer[0] + SHOOT_CADENCE;
        player_t[n].missile_id = missile(n);
    end
end

function throttle_update(n, throttle)
begin
    if (throttle == 0)
        player_t[n].vel = lerp(player_t[n].vel, 0, 100 - (100 / MAX_VELOCITY));
    else
        player_t[n].vel = clamp(player_t[n].vel + throttle, -MAX_VELOCITY, MAX_VELOCITY);
    end
end

process keyb_input(n, up_key, down_key, shoot_key)
private
    throttle = 0;
begin
    priority = player_t[n].pid.priority + 1;

    repeat
        if (player_t[n].state == PLAYER_STATE_MOVING)
            if (key(shoot_key))
                try_to_shoot(n);
            end

            throttle = 0;
            if (key(up_key))
                if (!key(down_key))
                    throttle = -1;
                end
            else if (key(down_key))
                throttle = 1;
            end end
            throttle_update(n, throttle);
        end
        frame;
    until (player_t[n].state == PLAYER_STATE_DEAD);
end


process missile(n)
private
    dir, id_collision;
begin
    x = player_t[n].pid.x;
    y = player_t[n].pid.y;
    flags = player_t[n].pid.flags & 3;
    angle = player_t[n].pid.angle;
    graph = 14;

    if (n == 0)
        dir = 8;
        x += 10;
    else
        dir = -8;
        x -= 10;
    end

    repeat
        frame;
        if (graph == 14) graph = 15; else graph = 14; end
        x += dir;
    // until (out_region(id, 0));
    until (x>260 and x<380);

    if (player_t[n].missile_id == id)
        player_t[n].missile_id = 0;
    end
end

/////////////////
//// EXPLOSION
/////////////////
function explosion(x,y,size);
begin
    graph=19;
    repeat
        if (size > 50 and rand(0,100)<size/10)
            clone
                x+=rand(-8,8);
                y+=rand(-8,8);
            end
        end
        size-=2;
        frame;
    until (size<25)
end

/////////////////
//// ENEMIES
/////////////////
process enemy(n, x, y, z, kind)
begin
end

process enemy_fire(n, x, y, z, graph1, graph2)
private
   vel_x = 300, vel_y;
begin
    graph=graph1;
    angle=player_t[n].pid.angle;
    flags=player_t[n].pid.flags & 3;
    resolution=100;

    if (n == 0) vel_x *= -1; end
    vel_y = player_t[n].pid.y - y;
    if (vel_y != 0)
        vel_y = (vel_y * vel_x) / (player_t[n].pid.x - x);
        vel_y = clamp(vel_y, -100, 100);
    end

    y *= resolution;
    x *= resolution;

    repeat
        if (graph == graph1)
            graph = graph2;
        else
            graph = graph1;
        end

        x += vel_x;
        y += vel_y;

        if (collision (TYPE explosion)) break; end

        frame;
    until (out_region(id,0))

end


/////////////////
//// HELPER TOOLS
/////////////////
function clamp(value, min, max)
begin
    if (value < min) return (min); end
    if (value > max) return (max); end

    return (value);
end

function lerp(a, b, t)
begin
    return ((a * t + b * (100 - t)) / 100);
end

process simple_sprite(x, y, z, file, graph)
begin
    loop
        frame;
    end
end

function path_resolve(file)
begin
    return (PATH_USER + "\" + PATH_PROG + "\" + file);
end
