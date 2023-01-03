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
    event disfrutar_atraccion(string, uint, address);
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

    //Dar de baja una atracciones en Dinsey
    function BajaAtraccion(string memory _nombreAtraccion) public Unicamente(msg.sender) AtraccionCorrecta(_nombreAtraccion){
        //El estado de la atraccion pasa a FALSE 
        MappingAtracciones[_nombreAtraccion].estado_atraccion = false;
        //Emitir el evento de baja de atracciones
        emit baja_atraccion(_nombreAtraccion);
    }

    //Verifica que la atraccion este en la lista
    modifier AtraccionCorrecta(string memory _nombre){
        //Se calcula el hash de la atraccion
        bytes32 hash_Atraccion = keccak256(abi.encodePacked(_nombre));
        //Inicializacion de la variable 
        bool atraccionEncontrada = false;

        //Se recorre el arreglo para verificar si el nombre de la atraccion es correcta
        for(uint i=0; i<Atracciones.length; i++){
            //Se compara el hash de la lista de atracciones con el hash de la atraccion ingresada
            if(keccak256(abi.encodePacked(Atracciones[i])) == hash_Atraccion){
                atraccionEncontrada = true;
            }
        }
        //Si el parametro ingresado no se encuentra en la lista falla
        require(atraccionEncontrada, "No se encuentra la atraccion");
        _;
    }

    //Visualizar las atracciones de Dinsey
    function AtraccionesDisponibles() public view returns(string [] memory){
        return Atracciones;
    }

    //Funciones para subirse a una atraccion de Dinsey y pagar con tokens
    function SubirAtraccion(string memory _nombreAtraccion) public {
        //Precio de la atraccion en tokens
        uint tokens_atraccion = MappingAtracciones[_nombreAtraccion].precio_atraccion;
        //Verifica el estado de la atraccion
        require (MappingAtracciones[_nombreAtraccion].estado_atraccion == true, "La atraccion no esta disponible en estos momentos.");
        //Verificar el numero de tokens del cliente
        require(tokens_atraccion <= MisToken(), "No tienes la cantidad necesario de token para comprar la atraccion");

        /* El cliente paga la atraccion en Tokens:
        -Ha sido necesario crear una funcion en ERC20.sol con el nombre: "transfer_dinsey"
        debido a que en caso de usar la Transfer o TransferFrom las direcciones que se usaban 
        para realizar la transaccion eran erroneas. Ya que el msg.sender que recibia el metodo
        era la direccion del propio contrato
        */
        token.transfer_dinsey(msg.sender, address(this), tokens_atraccion);
        //Almacenamiento en el historial
        HistorialAtracciones[msg.sender].push(_nombreAtraccion);
        //Emision del evento disfrutar_atraccion
        emit disfrutar_atraccion(_nombreAtraccion, tokens_atraccion, msg.sender);
    }

    //Visualizar eñ historial completo de atracciones disfrutadas por un cliente
    function Historial() public view returns (string [] memory){
        return HistorialAtracciones[msg.sender];
    }

    //Funcion para que un cliente de Dinsey pueda devolver Tokens al irse
    function DevolverTokens (uint _numTokens) public payable {
        //El numero de tokens a devolver es positivo
        require (_numTokens > 0, "Necesitas devolver una cantidad positiva de tokens.");
        //El usuario debe tener el numero de tokens que desea devolver
        require(_numTokens <= MisToken(), "No tienes los tokens que deseas devolver.");
        //El cliente devuelve los tokens
        token.transfer_dinsey(msg.sender, address(this), _numTokens);
        //Devolucion de ethers al cliente
        payable(msg.sender).transfer(PrecioToken(_numTokens));
    }
}