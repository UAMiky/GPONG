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

    MAX_VELOCITY = 10;
    SHOOT_CADENCE = 100;

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

begin
    load_resources();
    config_game();
    // main_menu();

    debug;
    exit("Fin", 0);
end

/////////////////
//// CONFIGURATION
/////////////////
function load_resources()
begin
end

function config_game()
begin
    set_mode(m640x400);
end

/////////////////
//// PLAYER AND CONTROL
/////////////////
process player(n, x, y, flags, angle)
begin
    player_t[n].pid = id;
    player_t[n].state = PLAYER_STATE_MOVING;
    player_t[n].lifes = 0;
    player_t[n].vel = 0;
    player_t[n].last_shoot_time = 0;

    loop
        
        // TODO: check collisions and handle life
        frame;
    end
end

function try_to_shoot(id_player)
begin
    if (timer[0] >= (player_t[id_player].last_shoot_time + SHOOT_CADENCE))
        player_t[id_player].last_shoot_time = timer[0];

        // TODO: shoot
    end
end

function throttle_update(id_player, throttle)
private int tmp_vel;
begin
    tmp_vel = lerp(player_t[id_player].vel, 0, 100 / MAX_VELOCITY);
    tmp_vel = clamp(tmp_vel + throttle, -MAX_VELOCITY, MAX_VELOCITY);
    player_t[id_player].vel = tmp_vel;
end

process keyb_input(id_player, up_key, down_key, shoot_key)
private
    throttle = 0;
begin
    priority = id_player.priority + 1;

    repeat
        if (player_t[id_player].state == PLAYER_STATE_MOVING)
            if (key(shoot_key))
                try_to_shoot(id_player);
            end

            throttle = 0;
            if (key(up_key))
                if (!key(down_key))
                    throttle = 1;
                end
            else if (key(down_key))
                throttle = -1;
            end end
            throttle_update(id_player, throttle);
        end
        frame;
    until (player_t[id_player].state == PLAYER_STATE_DEAD);
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
