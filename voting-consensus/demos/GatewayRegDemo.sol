pragma solidity ^0.5.0;


interface GatewayData{
    function registerGateway(address gatewayAdd) external;
    function removeGateway(address gatewayAdd) external;
}

contract GatewayRegDemo {
     GatewayData gd;
    
    constructor(address deployAddress) public {
        gd = GatewayData(deployAddress);
    }
    
    function registerGateway(address gatewayAdd) external {
        gd.removeGateway(gatewayAdd);
    }
    
    function removeGateway(address gatewayAdd) external {
        gd.removeGateway(gatewayAdd);
    }

}