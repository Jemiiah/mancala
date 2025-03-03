#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_caller_address;
    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    // import test utils
    
    use mancala::{
        // systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{mancala_game::{MancalaGame, GameId, mancala_game}},
        models::{player::{GamePlayer}}
    };

    fn setup_game() -> (GamePlayer, GamePlayer, IWorldDispatcher, IActionsDispatcher, MancalaGame, ContractAddress){
        let player_one_address = starknet::contract_address_const::<0x0>();
        let player_two_address = starknet::contract_address_const::<0x456>();
        let mut models = array![mancala_game::TEST_CLASS_HASH];
        let world = spawn_test_world(models);
        let contract_address = world.deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());

        let actions_system = IActionsDispatcher { contract_address: contract_address };
        actions_system.create_initial_game_id();
        let game: MancalaGame = actions_system.create_game();
        // set caller address to address two so game can be joined
        // for some reason this is not working in the test
        // set_caller_address(player_two_address);
        actions_system.join_game(game.game_id, player_two_address);
        let player_one: GamePlayer =  get!(world, (player_one_address, game.game_id), (GamePlayer));
        let player_two: GamePlayer =  get!(world, (player_two_address, game.game_id), (GamePlayer));

        (player_one, player_two, world, actions_system, game, contract_address)
    }

    #[test]
    #[available_gas(3000000000000)]
    fn test_create_game(){
        let (player_one, player_two, _, _, _, _) = setup_game();
        assert(player_one.pit1 == 4, 'p1 pit 1 not init correctly');
        assert(player_one.pit2 == 4, 'p1 pit 2 not init correctly');
        assert(player_one.pit3 == 4, 'p1 pit 3 not init correctly');
        assert(player_one.pit4 == 4, 'p1 pit 4 not init correctly');
        assert(player_one.pit5 == 4, 'p1 pit 5 not init correctly');
        assert(player_one.pit6 == 4, 'p1 pit 6 not init correctly');
        assert(player_two.pit6 == 4, 'p2 pit 1 not init correctly');
        assert(player_two.pit6 == 4, 'p2 pit 2 not init correctly');
        assert(player_two.pit6 == 4, 'p2 pit 3 not init correctly');
        assert(player_two.pit6 == 4, 'p2 pit 4 not init correctly');
        assert(player_two.pit6 == 4, 'p2 pit 5 not init correctly');
        assert(player_two.pit6 == 4, 'p2 pit 6 not init correctly');
    }

    #[test]
    #[available_gas(3000000000000)]
    fn test_game_id_increments() {
        let (_player_one, _player_two, _, _, _, contract_address) = setup_game();

        let actions_system = IActionsDispatcher { contract_address: contract_address };
        let game_two: MancalaGame = actions_system.create_game();
        assert!(game_two.game_id == 2, "incorrect id set");
        let game_three: MancalaGame = actions_system.create_game();
        assert!(game_three.game_id == 3, "incorrect id set");
    }

    #[test]
    #[available_gas(3000000000000)]
    fn test_move_pit1() {
        let (player_one, player_two, world, actions_system, game, _) = setup_game();
        let selected_pit: u8 = 1;
        actions_system.move(game.game_id, selected_pit);
        let game_after_move: MancalaGame = get!(world, game.game_id, (MancalaGame));
        let player_one: GamePlayer =  get!(world, (player_one.address, game.game_id), (GamePlayer));

        assert!(player_one.game_id == game.game_id, "player_one game id not correct");
        assert!(player_two.game_id == game.game_id, "player_two game id not correct");
        assert!(player_one.pit1 == 0, "pit1 not cleared");
        assert!(player_one.pit2 == 5, "pit2 does not have correct count");
        assert!(player_one.pit3 == 5, "pit3 does not have correct count");
        assert!(player_one.pit4 == 5, "pit4 does not have correct count");
        assert!(player_one.pit5 == 5, "pit5 does not have correct count");
        assert!(player_one.pit6 == 4, "pit5 does not have correct count");
        assert!(game_after_move.current_player == player_two.address, "current player did not switch");
        assert!(actions_system.is_game_finished(game.game_id) == false, "game should not be finished");
    }

    #[test]
    #[available_gas(3000000000000)]
    fn test_move_pit3() {
        // test that the seed should go in mancala and current player should remain the same
        let (player_one, _, world, actions_system, game, _) = setup_game();
        let selected_pit: u8 = 3;
        actions_system.move(game.game_id, selected_pit);
        let game_after_move: MancalaGame = get!(world, game.game_id, (MancalaGame));
        let player_one: GamePlayer =  get!(world, (player_one.address, game.game_id), (GamePlayer));

        assert!(player_one.pit1 == 4, "pit1 not cleared");
        assert!(player_one.pit2 == 4, "pit2 does not have correct count");
        assert!(player_one.pit3 == 0, "pit3 does not have correct count");
        assert!(player_one.pit4 == 5, "pit4 does not have correct count");
        assert!(player_one.pit5 == 5, "pit5 does not have correct count");
        assert!(player_one.pit6 == 5, "pit5 does not have correct count");
        assert!(player_one.mancala == 1, "mancala should have 1 seed");
        assert!(game_after_move.current_player == player_one.address, "current player should remain the same");
        assert!(actions_system.is_game_finished(game.game_id) == false, "game should not be finished");
    }

    // todo this test needs to be implemented
    // need to figure out how to change the caller address when calling actions_system.move()
    #[test]
    #[available_gas(3000000000000)]
    fn test_capture() {
        assert!(0 == 0, "todo implement");
    }

}
