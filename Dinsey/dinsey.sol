// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.9.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Dinsey{

    // ------------ DECLARACIONES INICIALES --------------------------

    // Instancia del contrato token
    ERC20Basic private token;
    //Direccion de Dinsey(owner)
    address payable public owner;

    constructor () public {
        token = new ERC20Basic(10000);
        owner = payable(msg.sender);
    }

    // Estructura de datos para almacenar los clientes de Dinsey
    struct cliente{
        uint tokens_comprados;
        string[] atracciones_disfrutadas;
    }

    // Mapping para el registro de clientes
    mapping (address => cliente) public Clientes;

    // ------------ GESTION DE TOKEN --------------------------

    // Function para establecer el precio de un token
    function PrecioToken(uint _numToken) internal pure returns(uint){
        //Devuelve la conversion de token a ether 1 token= 1 ether
        return _numToken * (1 ether);
    }
}