pragma solidity ^0.5.0;
import "./MyLibrary.sol";

contract FarmtoFork {
    
    enum produceStatus {Pending,Delivered}
    enum payStatus {Pending,Paid}
    enum bidproduceStatus {Pending,Rejected, Accepted}
    mapping (address => bool) private addressUsed;
    mapping (address => Farmer) private farmerDet;
    mapping (address => Aggregator) private aggrDet;
    mapping (address => Wholesaler) private wholesalerDet;
    mapping (uint32 => address) private mapFarmer ;
    mapping (uint32 => address) private mapAggr;
    mapping (uint32 => address) private mapWholesaler;
    mapping (uint32 => Produce) private produceDet;
    mapping (bytes32 => Produce) private produceDetnew;
    mapping (uint32 => bidProduce) private bidproduceDet;
    mapping (bytes32 => bidProduce) private bidDetnew;
    mapping (bytes32 => uint16) private inventoryDet;
    mapping (address => uint32) private currBalance;
    //address[] private reg_dup;
    uint32 private incFarmer=1;
    uint32 private incProduce=1;
    uint32 private incAggr=1;
    uint32 private incWholesaler=1;
    uint8 private transportId = 1;
    uint32 private incbid=1;
    address constant private transportAddrress = 0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7;
    string constant private transportName = "Here and there";

    
    struct Farmer {
        string farmerName; 
        uint32 farmerId; 
    }
    
    struct Produce {
        uint32 farmerId;
        string produceName; 
        uint16 weight; 
        uint32 produceId; 
        uint32 aggreId;
        uint32 produceAmt;
        uint8 paidstatus;
        uint8 deliverystatus;
    }
    
    struct Aggregator {
        string aggrName; 
        uint32 aggrId; 
    }
    
    struct Wholesaler {
        string wholesalerName; 
        uint32 wholeSalerId; 
    }
    
    struct bidProduce {
        string produceName; 
        uint16 weight; 
        uint32 bidId;
        uint32 aggreId;
        uint32 wholeSalerId;
        uint32 bidAmt;
        uint8 bidstatus;
        uint8 paidstatus;
        uint8 deliverystatus;
        uint8 transportpaystatus;
    }
    
    modifier checkDupreg(address addr) {
        require(addressUsed[addr] == false,"User already registered!! Cannot register again!");
        _;
    }
    
    modifier chkTransfer( bytes32 _producecombo, uint32 _amount) {
        Produce memory chkpa = produceDetnew[_producecombo];
        require(currBalance[mapAggr[chkpa.aggreId]] >= _amount,"Transaction Rejected! Insufficient balance");
       // require(chkpa.produceId != 0,"Transaction Rejected due to Invalid transaction!");
        assert(chkpa.produceId != 0);
        require(chkpa.paidstatus != uint8(payStatus.Paid),"Transaction Rejected! Farmer has already been paid for the produce");
        require(chkpa.deliverystatus == uint8(produceStatus.Delivered),"Transaction Rejected! Produce not yet delivered");
        _;
    }
    
    modifier checkappr(uint32 _wholeSalerId, uint32 _bidId) {
         //bytes32 bidcombo =  keccak256(abi.encodePacked(_wholeSalerId, _bidId));
         bytes32 bidcombo =  MyLibrary.encodeInputuint(_wholeSalerId, _bidId);
         bidProduce memory getp = bidDetnew[bidcombo];
         require(getp.bidstatus == uint8(bidproduceStatus.Pending),"Transaction Rejected!! Bid was already rejected/approved");
        //  require(getp.bidId != 0,"Transaction Rejected due to Invalid transaction!");
        //  require(getp.wholeSalerId != 0,"Transaction Rejected due to Invalid transaction!");
         assert(getp.bidId != 0);
         assert(getp.wholeSalerId != 0);
        _;
    }
    
    modifier chkTransferwholesaler( bytes32 _bidcombo, uint32 _amount) {
        bidProduce memory chkp = bidDetnew[_bidcombo];
        require(currBalance[mapWholesaler[chkp.wholeSalerId]] >= _amount,"Transaction Rejected! Insufficient balance");
        //require(chkp.bidId != 0,"Transaction Rejected due to Invalid transaction!");
        assert(chkp.bidId != 0);
        require(chkp.paidstatus != uint8(payStatus.Paid),"Transaction Rejected! Aggregator has already been paid for the bid");
        require(chkp.bidstatus == uint8(bidproduceStatus.Accepted),"Transaction Rejected! Aggregator is yet to approve the bid or already rejected  the bid");
        require(chkp.deliverystatus == uint8(produceStatus.Delivered),"Transaction Rejected! Produce not yet delivered");
        _;
    }
    
    modifier chkTransfertransporter( bytes32 _bidcombo, uint32 _amount) {
        bidProduce memory chkp = bidDetnew[_bidcombo];
        require(currBalance[mapAggr[chkp.aggreId]] >= _amount,"Transaction Rejected! Insufficient balance");
        //require(chkp.bidId != 0,"Transaction Rejected due to Invalid transaction!");
        assert(chkp.bidId != 0);
        require(chkp.transportpaystatus == uint8(payStatus.Pending),"Transaction Rejected! Transporter has already been paid for the bid");
        _;
    }
    
    function registerFarmer(address _farmeraddr, string calldata _farmername) 
    external checkDupreg(_farmeraddr) {
        Farmer storage f =farmerDet[_farmeraddr];
        f.farmerName = _farmername;
        f.farmerId = incFarmer++;
        mapFarmer[f.farmerId] = _farmeraddr;
        addressUsed[_farmeraddr] = true;
        //reg_dup.push(_farmeraddr);
    }
    
    function registerProduce(uint32 _farmerid, string calldata _produeName, uint16 _weight,uint32 _aggreId, uint32 _produceAmt) 
    external {
        Produce storage p =produceDet[_farmerid];
        p.farmerId = _farmerid;
        p.produceName = _produeName;
        p.produceId = incProduce++;
        p.weight = _weight;
        p.aggreId = _aggreId;
        p.produceAmt = _produceAmt;
        p.paidstatus = uint8(payStatus.Pending);
        p.deliverystatus = uint8(produceStatus.Pending);
        //bytes32 producecombo =  keccak256(abi.encodePacked(_farmerid, p.produceId));
        bytes32 producecombo = MyLibrary.encodeInputuint(p.farmerId , p.produceId);
        produceDetnew[producecombo] = p;
        //bytes32 inventorycombo =  keccak256(abi.encodePacked(p.aggreId, p.produceName));
        bytes32 inventorycombo = MyLibrary.encodeInputuintstring(p.aggreId, p.produceName);
        inventoryDet[inventorycombo] += p.weight;
    }
   
    function getFarmer(address _farmeraddr) external view returns(string memory, uint32 )  {
        Farmer memory getf =farmerDet[_farmeraddr];
        return (getf.farmerName, getf.farmerId);
    }
    
    function getProduce(uint32 _farmerid, uint32 _produceid) external view returns(string memory, uint16, uint32, uint8, uint8)  {
        //bytes32 producecombo =  keccak256(abi.encodePacked(_farmerid, _produceid));
        bytes32 producecombo =  MyLibrary.encodeInputuint(_farmerid, _produceid);
        Produce memory getp = produceDetnew[producecombo];
        return (getp.produceName, getp.weight, getp.produceId,getp.paidstatus,getp.deliverystatus);
    }
    
    function getbalance(address _addr) external view returns(uint) {
        return currBalance[_addr]; 
    }

    function getTransporter() external view returns(string memory, uint32)  {
       return (transportName,transportId);
    }

    function registerAggregator(address _aggrAddress, string calldata _aggrName) 
    external checkDupreg(_aggrAddress) {
        Aggregator storage f =aggrDet[_aggrAddress];
        f.aggrName = _aggrName;
        f.aggrId = incAggr++;
        mapAggr[f.aggrId] = _aggrAddress;
        //reg_dup.push(_aggrAddress);
        addressUsed[_aggrAddress] = true;
        currBalance[mapAggr[f.aggrId]] = 1000;
    }

    function markDeliveryFarmer(uint32 _aggreId, uint32 _farmerid,uint32 _produceId, uint32 _amount) external {
       //bytes32 producecombo =  keccak256(abi.encodePacked(_farmerid, _produceId));
        bytes32 producecombo =  MyLibrary.encodeInputuint(_farmerid, _produceId);
        Produce storage chkpf = produceDetnew[producecombo];
        require(chkpf.aggreId == _aggreId,"Transaction Rejected! Aggregator does not match from database");
        chkpf.deliverystatus = uint8(produceStatus.Delivered);
        payFarmer(producecombo,_amount) ;
    }

    function payFarmer(bytes32 _producecombo, uint32 _amount) private chkTransfer(_producecombo,_amount){
        Produce storage chkpr = produceDetnew[_producecombo];
        currBalance[mapFarmer[chkpr.farmerId]] += _amount;  
        currBalance[mapAggr[chkpr.aggreId]] -= _amount;  
        chkpr.paidstatus = uint8(payStatus.Paid);
    }
   
    function approvebid(uint32 _wholeSalerId, uint32 _bidId) external checkappr(_wholeSalerId,_bidId) {
         //bytes32 bidcombo =  keccak256(abi.encodePacked(_wholeSalerId, _bidId));
         bytes32 bidcombo = MyLibrary.encodeInputuint(_wholeSalerId, _bidId);
         bidProduce storage getp = bidDetnew[bidcombo];
         getp.bidstatus = uint8(bidproduceStatus.Accepted);
         getp.paidstatus = uint8(payStatus.Pending);
         //getp.deliverystatus = uint8(produceStatus.Pending);
    }
   
    function getInventory(string calldata _produceName, uint32 _aggreId) external view returns(uint32,string memory, uint16)  {
         //bytes32 inventorycombo =  keccak256(abi.encodePacked(_aggreId, _produceName));
         bytes32 inventorycombo =  MyLibrary.encodeInputuintstring(_aggreId, _produceName);
         return (_aggreId, _produceName, inventoryDet[inventorycombo]);
    }
    
    function getAggr(address _aggreAddress) external view returns(string memory, uint32)  {
       Aggregator memory getf =aggrDet[_aggreAddress];
        return (getf.aggrName, getf.aggrId);
    }

    function registerWholesaler(address _wholesaleAddress, string calldata _wholesalerName) 
    external checkDupreg(_wholesaleAddress) {
        Wholesaler storage f =wholesalerDet[_wholesaleAddress];
        f.wholesalerName = _wholesalerName;
        f.wholeSalerId = incWholesaler++;
        mapWholesaler[f.wholeSalerId] = _wholesaleAddress;
       //reg_dup.push(_wholesaleAddress);
        addressUsed[_wholesaleAddress] = true;
        currBalance[mapWholesaler[f.wholeSalerId]] = 1000;
    }
    
    function registerBid(uint32 _wholeSalerId, uint32 _aggreId, string calldata _produceName, uint16 _weight, uint32 _bidamount) 
    external  {
        bidProduce storage bp =bidproduceDet[_aggreId];
        bp.produceName = _produceName;
        bp.bidId = incbid++;
        bp.weight = _weight;
        bp.wholeSalerId = _wholeSalerId;
        bp.aggreId = _aggreId;
        bp.bidAmt = _bidamount;
        bp.bidstatus = uint8(bidproduceStatus.Pending);
        bp.paidstatus = uint8(payStatus.Pending);
       // bp.deliverystatus = uint8(produceStatus.Pending);
       //random value
        bp.deliverystatus = 9;
        bp.transportpaystatus = uint8(payStatus.Pending);
        //bytes32 bidcombo =  keccak256(abi.encodePacked(bp.wholeSalerId, bp.bidId));
        bytes32 bidcombo = MyLibrary.encodeInputuint(bp.wholeSalerId, bp.bidId);
        bidDetnew[bidcombo] = bp;
    }
    
    function getbid(uint32 _wholeSalerId, uint32 _bidId) external view returns(string memory, uint16, uint32, uint32, uint32,uint8, uint8, uint8)  {
         //bytes32 bidcombo =  keccak256(abi.encodePacked(_wholeSalerId, _bidId));
         bytes32 bidcombo =  MyLibrary.encodeInputuint(_wholeSalerId, _bidId);
         bidProduce memory getp = bidDetnew[bidcombo];
         return (getp.produceName, getp.weight, getp.bidAmt, getp.aggreId, getp.bidId,getp.bidstatus, getp.paidstatus,getp.deliverystatus);
    }
   
    function markDeliveryAggr(uint32 __wholeSalerId, uint32 _aggreId,uint32 _bidId) external {
       //bytes32 bidcombo =  keccak256(abi.encodePacked(__wholeSalerId, _bidId));
        bytes32 bidcombo =  MyLibrary.encodeInputuint(__wholeSalerId, _bidId);
        bidProduce memory chkp = bidDetnew[bidcombo];
        require(chkp.aggreId == _aggreId,"Transaction Rejected! Aggregator does not match from database");
        require(chkp.deliverystatus == uint8(produceStatus.Delivered),"Transaction Rejected! Produce not yet delivered to wholesaler. Contact Transporter.");
        //transport class should update the delivery status
        //chkp.deliverystatus = uint8(produceStatus.Delivered);
        payAggregator(bidcombo,chkp.bidAmt) ;
        //bytes32 inventorycombo =  keccak256(abi.encodePacked(chkp.aggreId, chkp.produceName));
        bytes32 inventorycombo = MyLibrary.encodeInputuintstring(chkp.aggreId, chkp.produceName);
        inventoryDet[inventorycombo] -= chkp.weight;
    }
    
//   function payTransfer(address _farmeraddr, uint32 _amount) public payable {
//       _farmeraddr.transfer(_amount);
//   }

    function payAggregator(bytes32 _bidcombo, uint32 _amount) private chkTransferwholesaler(_bidcombo,_amount){
        bidProduce storage chkp = bidDetnew[_bidcombo];
        currBalance[mapWholesaler[chkp.wholeSalerId]] -= _amount;  
        currBalance[mapAggr[chkp.aggreId]] += _amount;  
        chkp.paidstatus = uint8(payStatus.Paid);
      // payTransfer(mapFarmer[_farmerid],_amount);
    }
   
    function getWholesaler(address _wholesaleAddressl) external view returns(string memory, uint32)  {
       Wholesaler memory getf =wholesalerDet[_wholesaleAddressl];
        return (getf.wholesalerName, getf.wholeSalerId);
    }
    
    function initiateTransport(uint32 _wholeSalerId, uint32 _aggreId,uint32 _bidId) external {
       //bytes32 bidcombo =  keccak256(abi.encodePacked(_wholeSalerId, _bidId));
        bytes32 bidcombo =  MyLibrary.encodeInputuint(_wholeSalerId, _bidId);
        bidProduce storage chkp = bidDetnew[bidcombo];
        require(chkp.aggreId == _aggreId,"Transaction Rejected! Aggregator does not match from database");
        require(chkp.wholeSalerId == _wholeSalerId,"Transaction Rejected! Wholesaler does not match from database");
        require(chkp.deliverystatus != uint8(produceStatus.Pending),"Transaction Rejected! Transport already in progress");
        require(chkp.deliverystatus != uint8(produceStatus.Delivered),"Transaction Rejected! Produce has been already delivered");
        chkp.deliverystatus = uint8(produceStatus.Pending);
    }
    
	function markDeliveryTransport(uint32 _wholeSalerId, uint32 _aggreId,uint32 _bidId, uint32 _amount) external {
       //bytes32 bidcombo =  keccak256(abi.encodePacked(_wholeSalerId, _bidId));
        bytes32 bidcombo =  MyLibrary.encodeInputuint(_wholeSalerId, _bidId);
        bidProduce storage chkp = bidDetnew[bidcombo];
        require(chkp.aggreId == _aggreId,"Transaction Rejected! Aggregator does not match from database");
        require(chkp.wholeSalerId == _wholeSalerId,"Transaction Rejected! Wholesaler does not match from database");
        require(chkp.deliverystatus == uint8(produceStatus.Pending),"Transaction Rejected! Produce may have been already delivered to wholesaler. Contact Transporter.");
        chkp.deliverystatus = uint8(produceStatus.Delivered);
        payTransporter(bidcombo,_amount) ;
    }
    
    function payTransporter(bytes32 _bidcombo, uint32 _amount) private chkTransfertransporter(_bidcombo,_amount){
        bidProduce storage chkp = bidDetnew[_bidcombo];
        currBalance[mapAggr[chkp.aggreId]] -= _amount;  
        currBalance[transportAddrress] += _amount;  
        chkp.transportpaystatus = uint8(payStatus.Paid);
    }
}
