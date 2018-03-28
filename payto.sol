//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.4.18;

contract PayTo {
  
enum accountStatus {
  active,
  inactive,
  suspended
}

uint commissionPercentage = 1;

  //start company data structure
  struct Company {
  address companyAddress;
  bytes32 companyName;
  accountStatus companyStatus;
  }

 Company[] company;
 mapping (address => uint32[]) companyAddressToServiceIndices;
 mapping (address => uint32) companyAddressToIndex;

  //start Services data structure
mapping (bytes32 => uint) serviceNameToIndex;
struct Service { 
  bytes32 serviceName;
  uint32 serviceCost;
  bytes32 companyName;
  accountStatus serviceStatus;
  }
Service[] service;

//start Subscriber datastructure 
mapping (address => uint) subscriberAddressToIndex;
Subscriber[] subscriber;
struct Subscriber {
   address subscriberAddress; 
   bytes32 userName;
   uint balances;  
   accountStatus subscriberStatus;
   }

mapping (address => uint32[]) subscriberAddressToSubscriptionIndices;
//mapping (address => uint32[]) serviceNameToSubscriptionIndices; //added to show
Subscription[] subscriptions;
struct Subscription {
   bytes32 serviceName;
   accountStatus subscriptionStatus;
   uint256 subscriberSince;
   address userAddress;
  }
// needs to be memory
  mapping (bytes32 => payoutForService) serviceNameToPaymentAmtStruct;

struct payoutForService{
uint totalPayoutAmountForService;
address[] paidCustomers;
uint timeStamp;
}

//start methods
modifier subscriberExistsAndActive(){
  uint _subId = subscriberAddressToIndex[msg.sender];
  require(_subId < subscriber.length);
  require(subscriber[_subId].subscriberAddress == msg.sender);
  require(subscriber[_subId].subscriberStatus == accountStatus.active);
  _;
}

function subscriberExists() private view returns (bool exists){
  uint _subId = subscriberAddressToIndex[msg.sender];
  if((_subId < subscriber.length) && (subscriber[_subId].subscriberAddress == msg.sender) )
  {
      return true;
  } else return false;
}

function companyExists() private view returns (bool exists){
  uint _companyId = companyAddressToIndex[msg.sender];
  if((_companyId < company.length) && (company[_companyId].companyAddress == msg.sender) )
  {
      return true;
  } else return false;
}


modifier subscriberDoesntExistOrInactive(){
  uint _subId = subscriberAddressToIndex[msg.sender];
  if(subscriberExists()){
    require(subscriber[_subId].subscriberStatus == accountStatus.inactive);
  }
  _;
}

modifier companyDoesntExistOrInactive(){
  uint _companyId = companyAddressToIndex[msg.sender];
  if(companyExists()){
    require(company[_companyId].companyStatus == accountStatus.inactive);
  }
  _;
}
function serviceExists(bytes32 _serviceName) private view returns (bool exists){
  uint _serviceId = serviceNameToIndex[_serviceName];
  if((_serviceId < service.length) && 
        (keccak256(service[_serviceId].serviceName) == keccak256(msg.sender)))
  {
      return true;
  } else return false;
}

modifier serviceExistsAndActive(bytes32 _serviceName){
uint32 _serviceId = uint32(serviceNameToIndex[_serviceName]);
require(_serviceId < service.length);
require(keccak256(service[_serviceId].serviceName) == keccak256(_serviceName));
require(service[_serviceId].serviceStatus == accountStatus.active);
_;
}

modifier serviceDoesntExistsOrInactive(bytes32 _serviceName){
  uint _serviceId = serviceNameToIndex[_serviceName];
  if(serviceExists(_serviceName)){
    require(service[_serviceId].serviceStatus == accountStatus.inactive);
  }
  _;
}


modifier servicesExistsAndActive(bytes32 _serviceName){
uint _serviceId = serviceNameToIndex[_serviceName];
require(_serviceId < service.length);
require(keccak256(service[_serviceId].serviceName) == keccak256(_serviceName));
require(service[_serviceId].serviceStatus == accountStatus.active);
_;
}

modifier companyExistsAndActive(){
  uint _companyId = companyAddressToIndex[msg.sender];
  require(_companyId < company.length);
  require(company[_companyId].companyStatus == accountStatus.active);
  _;
}

/*
This function is to register as a new Subscriber or for some reason if the user chose to deregister earlier and comes back to register again
input should a string of the userName - the identification for the user/subscriber on the Application
*/
function registerAsSubscriber(bytes32 _userName) public subscriberDoesntExistOrInactive {
 //Subscription[] _newSub;
  uint _subId = subscriberAddressToIndex[msg.sender];
  if(_subId < subscriber.length)
  {
    subscriber[_subId].subscriberStatus=accountStatus.active;
  } else{
  Subscriber memory _newSubscriber =  Subscriber(msg.sender, _userName, 0, accountStatus.active);
  uint _newSubscriberId = subscriber.push(_newSubscriber);
  subscriberAddressToIndex[msg.sender] = _newSubscriberId;
  }
} //- [send money initially] // subscriber doesn’t exists  or is in active (modifiers)


/*
This function is  used by the user to load money into their account. 
There's no input argument needed since the account will be retrieved using the address that's calling this function
*/
function loadMoneyAsSubscriber() subscriberExistsAndActive public payable{
  uint _subId = subscriberAddressToIndex[msg.sender]; 
  subscriber[_subId].balances += msg.value;
}

/*
The purpose of this function is for already registered subscriber to view their balance
No input required since the account is retrieved through the address this function is called from.
*/
function ViewBalances() subscriberExistsAndActive view public returns (uint _subscriberBalance) {
  uint _subId = subscriberAddressToIndex[msg.sender]; 
  return subscriber[_subId].balances;
}

/*
The purpose of this function is to check if the subscription with a service already exists for the calling registered subscriber. 
This a helper function that gets called by other functions to validate conditions before a certain
*/
function checkIfSubscriptionExists(bytes32 _serviceName) view private
  returns (bool _serviceExists, uint32 _subscriptionArrayIndex){
uint32[] storage _existingSubscriptionIds = subscriberAddressToSubscriptionIndices[msg.sender];
//length > 0 already part of for loop
for(uint32 _index=0; _index < _existingSubscriptionIds.length; _index++)
  {
    if( (keccak256(subscriptions[_existingSubscriptionIds[_index]].serviceName) == 
    keccak256(_serviceName)) && 
    ((subscriptions[_existingSubscriptionIds[_index]].userAddress) == 
     (subscriber[subscriberAddressToIndex[msg.sender]].subscriberAddress)) )
    {
        return(true, _existingSubscriptionIds[_index]);
    } 
  }
return(false, 0);
}

/*
The purpose of this function is for the already registered subscriber to subscribe for a specific offered service under a company
*/
//Subscribe for services - notify company (event) - SubscribeToAServiceFromACompany()
function subscribeForServices(bytes32 _serviceName) subscriberExistsAndActive
   servicesExistsAndActive(_serviceName) public returns (bool){
     bool _subExists;
     uint32 _subIndex;
    (_subExists,_subIndex) = checkIfSubscriptionExists(_serviceName);
    if(_subExists)
    {
      subscriptions[_subIndex].subscriptionStatus = accountStatus.active;
      subscriptions[_subIndex].subscriberSince = now;
    } else {
    Subscription memory _newSubscription;
    _newSubscription = Subscription(_serviceName, accountStatus.active, now, 
    subscriber[subscriberAddressToIndex[msg.sender]].subscriberAddress);
    uint32 _subscriptionId = uint32(subscriptions.push(_newSubscription));
    uint32[] storage _subIndices = subscriberAddressToSubscriptionIndices[msg.sender];
    _subIndices.push(_subscriptionId);
   // uint32[] _subIndices = serviceNameToSubscriptionIndices[_serviceName]; //added to show
    //_subIndices.push(_subscriptionId); //added to show

   }
return true;
}

/*
Purpose of this function is for the registered subscriber to cancel their currently active subscription
*/

function cancelSubscriptionForService(bytes32 _serviceName) subscriberExistsAndActive
   servicesExistsAndActive(_serviceName) public returns (bool){
    bool _subExists;
     uint32 _subIndex;
    (_subExists,_subIndex) = checkIfSubscriptionExists(_serviceName);
      require(_subExists);
      subscriptions[_subIndex].subscriptionStatus = accountStatus.inactive;
      subscriptions[_subIndex].subscriberSince = now;
    
}

/*
The purpose of this function is for the registered subscriber to withdraw money from their account
The input required is the amount they want to withdraw
*/
 function withdrawMoney(uint amt) subscriberExistsAndActive public returns (bool) {
   uint _subId = subscriberAddressToIndex[msg.sender]; 
   require(subscriber[_subId].balances >= amt);
   subscriber[_subId].balances -= amt;
   msg.sender.transfer(amt);
   return true;
 }

/*
The purpose of this function is for already registered active subscriber to deregister and stop using our service/application
*/
 function deregisterAsSubscriber() subscriberExistsAndActive public{
      uint _subId = subscriberAddressToIndex[msg.sender]; 
    uint32[] storage _subscriptionIndices = subscriberAddressToSubscriptionIndices[msg.sender];
    for(uint32 _index=0; _index<_subscriptionIndices .length; _index++)
    {
    cancelSubscriptionForService(subscriptions[_subscriptionIndices[_index]].serviceName);
    }
     withdrawMoney(subscriber[_subId].balances);
 }

/*
The purpose of this function is for a company to register it with our application to offer services and charge customers for autopay
*/

function registerAsCompany(bytes32 _companyName) companyDoesntExistOrInactive public{
  if(companyExists())
  {
    uint32 _companyId = companyAddressToIndex[msg.sender];
    company[_companyId].companyStatus=accountStatus.active;
  } else{
  Company memory _newCompany =  Company(msg.sender, _companyName, accountStatus.active);
  uint _newcompanyId = company.push(_newCompany);
  companyAddressToIndex[msg.sender] = uint32(_newcompanyId);
  }
}


/*
This is a helper function to deactivate subscriptions for a particular service
input expected is service name
*/

function deactiveSubscriptionsForService(bytes32 _serviceName) private {
 for(uint32 _subscriptionIndex=0; _subscriptionIndex<subscriptions.length; _subscriptionIndex++)
      {
        if(keccak256(subscriptions[_subscriptionIndex].serviceName)==(keccak256(_serviceName))){
          subscriptions[_subscriptionIndex].subscriptionStatus=accountStatus.inactive;
        }
      }
}

/*
This is a  helper function to deactive a particular service 
The input expected is the index in the service array
*/
function deactivateService(uint32 _serviceIndex) private {
      service[_serviceIndex].serviceStatus=accountStatus.inactive;
      deactiveSubscriptionsForService(service[_serviceIndex].serviceName);
}

/*
The purpose of this function is for an active registered company to deregister from our application and stop using it. 
*/
function deregisterAsCompany() companyExistsAndActive public{
    uint32[] storage _servicesIndices = companyAddressToServiceIndices[msg.sender];
    for(uint32 _index=0; _index<_servicesIndices.length; _index++)
    {
      deactivateService(_servicesIndices[_index]);
    }  
 }

/*
The purpose of this function is for a company to deregister/discontinue a service 
*/
function deregisterServiceAsCompany(bytes32 _serviceName) serviceExistsAndActive(_serviceName) 
    companyExistsAndActive() 
        public returns (bool){
    uint32[] storage _serviceIndices = companyAddressToServiceIndices[msg.sender];
    for(uint32 _index; _index<_serviceIndices.length; _index++){
      if( keccak256(service[_serviceIndices[_index]].serviceName) == keccak256(_serviceName) ){
        deactivateService(_serviceIndices[_index]);
        return true;
      } 
    }
    return false;
 }

/*
The purpose of this function is for a company to register a service
input parameters required are the service name and the cost
*/

function registerServiceAsCompany(bytes32 _serviceName, uint32 _cost) 
    public serviceDoesntExistsOrInactive(_serviceName) companyExistsAndActive returns (bool){
    if(serviceExists(_serviceName))
    {
      service[serviceNameToIndex[_serviceName]].serviceCost = _cost;
      service[serviceNameToIndex[_serviceName]].serviceStatus = accountStatus.active;
    } else {
    Service memory _newService;
    _newService = Service(_serviceName, _cost, company[companyAddressToIndex[msg.sender]].companyName, accountStatus.active);
    uint32 _serviceId = uint32(service.push(_newService));
    serviceNameToIndex[_serviceName]=_serviceId;
    uint32[] storage _serviceIndices = companyAddressToServiceIndices[msg.sender];
   _serviceIndices.push(_serviceId);
   companyAddressToServiceIndices[msg.sender]=_serviceIndices;
   }
  return true;
}


/*
The purpose of this function is to calculate payment for all Services altogether. This is a private helper function to be able during the payment on the 1st of the every month
*/

function calcPaymentForServices() private {
  uint _timeStamp = now;
  for(uint32 _subIndex; _subIndex<subscriptions.length;_subIndex++)
  {
  address _uAddress = subscriptions[_subIndex].userAddress;
   
   Service storage _serviceInstance = service[serviceNameToIndex[subscriptions[_subIndex].serviceName]];
  if(subscriptions[_subIndex].subscriptionStatus==accountStatus.active && 
    subscriber[subscriberAddressToIndex[_uAddress]].balances>= _serviceInstance.serviceCost)
  {
    subscriber[subscriberAddressToIndex[_uAddress]].balances =- _serviceInstance.serviceCost; 
    payoutForService storage _servicePayoutInstance =  serviceNameToPaymentAmtStruct[_serviceInstance.serviceName];
        if(_timeStamp==_servicePayoutInstance.timeStamp)
        {
            _servicePayoutInstance.totalPayoutAmountForService += _serviceInstance.serviceCost;
            _servicePayoutInstance.paidCustomers.push(subscriber[subscriberAddressToIndex[_uAddress]].subscriberAddress);
        } else {
             delete _servicePayoutInstance.paidCustomers;
             _servicePayoutInstance.totalPayoutAmountForService=_serviceInstance.serviceCost;
            _servicePayoutInstance.timeStamp=_timeStamp;
            //_servicePayoutInstance.paidCustomers.length=0;
            _servicePayoutInstance.paidCustomers.push(subscriber[subscriberAddressToIndex[_uAddress]].subscriberAddress);
        }
  } else if(subscriptions[_subIndex].subscriptionStatus==accountStatus.active) {
    subscriptions[_subIndex].subscriptionStatus=accountStatus.inactive;
  }
  }
}


function calcTotalPayoutForCompany(address _companyAddr) private view returns (uint){
uint totalamountForCompany=0;
uint32[] storage _serviceIndices = companyAddressToServiceIndices[_companyAddr];
for(uint _sIndex=0; _sIndex<_serviceIndices.length;_sIndex++)
  {
    payoutForService storage _paymentForService =
       serviceNameToPaymentAmtStruct[service[_serviceIndices[_sIndex]].serviceName];
       if(now - _paymentForService.timeStamp <= 1 hours) //handle 0 subscribers for service giving old values
       {
          totalamountForCompany += _paymentForService.totalPayoutAmountForService;
       }
  } 
  return totalamountForCompany;
}

/*
This is an internal function for transferring funds out to the company
inputs required are the address, and the payout amount.
*/
function transferFunds(address _addr, uint _payout) internal{
  _addr.transfer(_payout);
}

/*
The purpose of this function is to calculate the commission for every payout to the company
input required is the total Payout amount
*/
function calcCommission(uint _totalPayout) private view returns (uint){
  uint _commission =  _totalPayout * (1-commissionPercentage/100);
  return _commission;
}

/*
The purpose of this function is to intiate payout on a particular date of every month (1st)
*/
function initatePayout() public //onlyOwner{
  {
  for(uint32 _compIndex=0; _compIndex<company.length;_compIndex++)
      {
        uint totalPayout = calcTotalPayoutForCompany(company[_compIndex].companyAddress);
        uint commission = calcCommission(totalPayout);
        require(commission<totalPayout);
        transferFunds(company[_compIndex].companyAddress,totalPayout-commission); //safeMath
      }
    }
    
}
    
