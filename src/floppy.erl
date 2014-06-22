-module(floppy).
-include("floppy.hrl").
-include_lib("riak_core/include/riak_core_vnode.hrl").

-export([append/2,
         read/2]).

%% Public API

append(Key, Op) ->
    lager:info("Append called!"),
    floppy_rep_vnode:append(Key, Op).

read(Key, Type) ->
    case floppy_rep_vnode:read(Key, Type) of
        {ok, Ops} ->
            Init=materializer:create_snapshot(Type),
            Snapshot=materializer:update_snapshot(Type, Init, Ops),
            Type:value(Snapshot);
        {error, Reason} ->
            lager:info("Read failed: ~w~n", Reason),
	    error
    end.
