use starknet::ContractAddress;

#[abi]
trait IManager {
    fn owner() -> ContractAddress;
    fn set_permit(account: ContractAddress, right: felt252, timestamp: u64);
    fn bind_manager_right(right: felt252, manager_right: felt252);
}

#[abi]
trait IRbits {
    fn balance_of(account: ContractAddress) -> u256;
    fn mint(recipient: ContractAddress, amount: u256);
    fn burn(owner: ContractAddress, amount: u256);
    fn MINT_RBITS() -> felt252;
    fn BURN_RBITS() -> felt252;
}

#[cfg(test)]
mod EntryPoint {
    use manager::manager::Manager;
    use rbits::rbits::Rbits;

    use super::IManagerDispatcher;
    use super::IManagerDispatcherTrait;

    use super::IRbitsDispatcher;
    use super::IRbitsDispatcherTrait;

    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::testing::set_contract_address;
    use starknet::syscalls::deploy_syscall;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_caller_address;
    use starknet::get_caller_address;

    use debug::PrintTrait;
    use array::ArrayTrait;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    use result::ResultTrait;

    fn deploy_suite() -> (IManagerDispatcher, IRbitsDispatcher) {
        let owner = contract_address_const::<123>();
        set_contract_address(owner);

        let mut calldata = ArrayTrait::new();
        calldata.append(owner.into());

        let (manager_address, _) = deploy_syscall(
            Manager::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        let mut calldata = ArrayTrait::new();
        // let init, owner, mananger
        let init_supply_low = 123_u128;
        let init_supply_high = 0_u128;
        calldata.append(init_supply_low.into());
        calldata.append(init_supply_high.into());
        calldata.append(owner.into());
        calldata.append(manager_address.into());

        let (rbits_address, _) = deploy_syscall(
            Rbits::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        (
            IManagerDispatcher {
                contract_address: manager_address
                }, IRbitsDispatcher {
                contract_address: rbits_address
            }
        )
    }

    #[test]
    #[available_gas(2000000)]
    fn mint_owner() {
        let (Manager, Rbits) = deploy_suite();
        let anon = contract_address_const::<'anon'>();

        Rbits.mint(anon, 1_u256);
        assert(Rbits.balance_of(anon) == 1_u256, 'Mints wrong amount');
    }

    #[test]
    #[available_gas(2000000)]
    fn burn_owner() {
        let (Manager, Rbits) = deploy_suite();
        let anon = contract_address_const::<'anon'>();
        Rbits.burn(Manager.owner(), 1_u256);
        assert(Rbits.balance_of(Manager.owner()) == 122_u256, 'Burns wrong amount');
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('RBITS: Caller non minter', 'ENTRYPOINT_FAILED'))]
    fn mint_no_permit() {
        let (Manager, Rbits) = deploy_suite();
        let anon = contract_address_const::<'anon'>();
        set_contract_address(anon);
        Rbits.mint(anon, 1_u256);
    }

    #[test]
    #[available_gas(2000000)]
    #[should_panic(expected: ('RBITS: Caller non burner', 'ENTRYPOINT_FAILED'))]
    fn burn_no_permit() {
        let (Manager, Rbits) = deploy_suite();
        let anon = contract_address_const::<'anon'>();
        set_contract_address(anon);
        Rbits.burn(Manager.owner(), 1_u256);
    }

    #[test]
    #[available_gas(2000000)]
    fn mint_with_permit() {
        let (Manager, Rbits) = deploy_suite();
        let anon = contract_address_const::<'anon'>();
        Manager.set_permit(anon, Rbits.MINT_RBITS(), 999);
        set_contract_address(anon);
        Rbits.mint(anon, 1_u256);
        assert(Rbits.balance_of(anon) == 1_u256, 'Mints wrong amount');
    }

    #[test]
    #[available_gas(2000000)]
    fn burn_with_permit() {
        let (Manager, Rbits) = deploy_suite();
        let anon = contract_address_const::<'anon'>();
        Manager.set_permit(anon, Rbits.BURN_RBITS(), 999);
        set_contract_address(anon);
        Rbits.burn(Manager.owner(), 122_u256);
        assert(Rbits.balance_of(Manager.owner()) == 1_u256, 'Mints wrong amount');
    }

    #[test]
    #[available_gas(2000000)]
    fn mint_with_delegated_permit() {
        let (Manager, Rbits) = deploy_suite();
        let manager = contract_address_const::<'manager'>();
        let anon = contract_address_const::<'anon'>();

        let right = Rbits.MINT_RBITS();
        let manager_right = 'MINT RBITS MANAGER';

        Manager.set_permit(manager, manager_right, 999);
        Manager.bind_manager_right(right, manager_right);

        set_contract_address(manager);
        Manager.set_permit(anon, right, 999);

        set_contract_address(anon);
        Rbits.mint(anon, 1_u256);
        assert(Rbits.balance_of(anon) == 1_u256, 'Mints wrong amount');
    }

    #[test]
    #[available_gas(2000000)]
    fn burn_with_delegated_permit() {
        let (Manager, Rbits) = deploy_suite();
        let manager = contract_address_const::<'manager'>();
        let anon = contract_address_const::<'anon'>();

        let right = Rbits.BURN_RBITS();
        let manager_right = 'BURN RBITS MANAGER';

        Manager.set_permit(manager, manager_right, 999);
        Manager.bind_manager_right(right, manager_right);

        set_contract_address(manager);
        Manager.set_permit(anon, right, 999);

        set_contract_address(anon);
        Rbits.burn(Manager.owner(), 122_u256);
        assert(Rbits.balance_of(Manager.owner()) == 1_u256, 'Mints wrong amount');
    }
}

