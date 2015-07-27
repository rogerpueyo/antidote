%% -------------------------------------------------------------------
%%
%% Copyright (c) 2014 SyncFree Consortium.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(dc_utilities).

-export([get_my_dc_id/0, get_my_dc_nodes/0, call_vnode_sync/3, bcast_vnode_sync/2, partition_to_indexnode/1, get_num_partitions/0, call_vnode/3, debug_get_vectorclocks/0, get_partitions/0, bcast_vnode/2]).

get_my_dc_id() ->
    {ok, Ring} = riak_core_ring_manager:get_my_ring(),
    riak_core_ring:cluster_name(Ring).

get_my_dc_nodes() ->
    {ok, Ring} = riak_core_ring_manager:get_my_ring(),
    riak_core_ring:all_members(Ring).

partition_to_indexnode(Partition) ->
    {ok, Ring} = riak_core_ring_manager:get_my_ring(),
    Node = riak_core_ring:index_owner(Ring, Partition),
    {Partition, Node}.

get_num_partitions() ->
    {ok, Ring} = riak_core_ring_manager:get_my_ring(),
    riak_core_ring:num_partitions(Ring).

get_partitions() -> %% TODO: this is a hack, implement this properly!
    VNodes = riak_core_vnode_manager:all_index_pid(logging_vnode),
    Num = get_num_partitions(),
    case length(VNodes) of
        Num -> lists:map(fun({P, _}) -> P end, VNodes);
        _ -> timer:sleep(100), get_partitions()
    end.

call_vnode_sync(Partition, VMaster, Request) ->
    riak_core_vnode_master:sync_command(partition_to_indexnode(Partition), Request, VMaster).

call_vnode(Partition, VMaster, Request) ->
    riak_core_vnode_master:command(partition_to_indexnode(Partition), Request, VMaster).

bcast_vnode_sync(VMaster, Request) ->
    lists:map(fun(P) -> {P, call_vnode_sync(P, VMaster, Request)} end, get_partitions()).

bcast_vnode(VMaster, Request) ->
    lists:map(fun(P) -> {P, call_vnode(P, VMaster, Request)} end, get_partitions()).

debug_get_vectorclocks() ->
    F = fun(P) ->
        {ok, C} = vectorclock:get_clock(P),
        R = {P, dict:to_list(C)},
        lager:info("~p", [R]),
        R
    end,
    lists:map(F, get_partitions()).

