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

    PLAYER_GRAPH = 13;

    ANIM_DIE_FIRST = 19;
    ANIM_DIE_LAST  = 19;
    ANIM_DIE_SPEED = 500;

    MIN_Y = 16;
    MAX_Y = 360 - 16;

    PLAYER_INVULNERABLE_TIME = 150;

global
    struct player_t[1]
        int pid;
        int state;
        int lifes;
        int vel;
        int last_shoot_time;
    end =
    0, PLAYER_STATE_DEAD, 3, 0, 0,
    0, PLAYER_STATE_DEAD, 3, 0, 0;

    int g_file;

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

    player(1, 640-16, 180, 1, -90000);
    keyb_input(1, _p, _l, _m);

    simple_sprite(16, 100, 1, g_file, 5);

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
end

/////////////////
//// PLAYER AND CONTROL
/////////////////
process player(n, x, y, flags, angle)
begin
    player_t[n].pid = id;
    player_t[n].state = PLAYER_STATE_MOVING;
    player_t[n].lifes = 0;    // TODO: initialize to MAX_LIFES in single player mode
    player_t[n].vel = 0;
    player_t[n].last_shoot_time = 0;
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
                    if (collision (TYPE simple_sprite) )
                        player_starts_dying(n);
                    end
                end
            end

            case PLAYER_STATE_DYING:
                for (graph = ANIM_DIE_FIRST; graph <= ANIM_DIE_LAST; ++graph)
                    frame(ANIM_DIE_SPEED);
                end

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
    if (timer[0] >= (player_t[n].last_shoot_time + SHOOT_CADENCE))
        player_t[n].last_shoot_time = timer[0];

        // TODO: shoot
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
