// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.9.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Dinsey{

    // ------------ DECLARACIONES INICIALES ------------------------

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

    // Funcion para comprar token
    function CompraToken(uint _numToken) public payable{
        // Establecer el precio de lo token
        uint coste = PrecioToken(_numToken);
        // Se evalua el dinero que el cliente paga por los tokens
        require (msg.value >= coste, "Compra menos Tokens o paga con mas ethers.");
        // Diferencia de lo que el cliente paga
        uint returnValue = msg.value - coste;
        //Dinsey retorna la cantidad de ethers al cliente
        payable(msg.sender).transfer(returnValue);
        // Obtencion del numero de token disponible
        uint Balance = balanceOf();
        require(_numToken <= Balance, "Compra un numero menor de Tokens");
        // se transfiere el numero de tokens al cliente
        token.transfer(msg.sender, _numToken);
        // Registro de clos tokens comprados
        Clientes[msg.sender].tokens_comprados += _numToken;
    }

    // Balance de token  del contrato dinsey
    function balanceOf() public view returns (uint){
        return token.balanceOf(address(this));
    }

    // Para visualizar la cantidad de token restantes de un cliente
    function MisToken() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    // Funciona para generar mas token
    function GeneraToken(uint _numTokens) public Unicamente(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    //Modificador para controlar las funciones ejecutables por dinsey
    modifier Unicamente(address _direccion){
        require(_direccion == owner, "No tienes permisos para ejecutar esta funcion");
        _;
    }

    // ------------ GESTION DE TOKEN --------------------------

    //Eventos
    event disfruta_attracciones(string);
    event nueva_atraccion(string, uint);
    event baja_atraccion(string);

    //Estructura de datos de la atraccion
    struct atraccion{
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }

    //Mapping para relacionar un nombre de una atraccion con una estructura de datos de una atraccion
    mapping (string => atraccion) public MappingAtracciones;
    
    //Array de almacenamiento de nombre de atracciones
    string [] Atracciones;

    // Mapping para relacionar una identidad (cliente) con su historial en Dinsey
    mapping (address => string[]) HistorialAtracciones;

    //Nos permite crear nuevas atracciones para Dinsey(Solo es ejecutado por Dinsey)
    function NuevaAtraccion(string memory _nombreAtraccion, uint _precio) public Unicamente(msg.sender){
        // Creacion de una atraccion en Dinsey
        MappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion, _precio, true);
        //Almacenar en un array el nomrbe de la atraccion
        Atracciones.push(_nombreAtraccion);
        //Emision del evento para la nueva atraccion
        emit nueva_atraccion(_nombreAtraccion, _precio);
    }

}