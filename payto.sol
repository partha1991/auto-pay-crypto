//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.4.18;

contract PayTo {
  
enum accountStatus {
  active,
  inactive,
  suspended
}

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
mapping (bytes32 => uint32) serviceNameToIndex;
struct Service { 
  bytes32 serviceName;
  uint cost;
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
Subscription[] subscriptions;
struct Subscription {
   bytes32 serviceName;
   accountStatus subscriptionStatus;
   uint256 subscriberSince;
   bytes32 userName;
  }
// needs to be memory
  mapping (bytes32 => uint) serviceToTotalMonthlyPayoutAmount;

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

function serviceExists(bytes32 _serviceName) private view returns (bool exists){
  uint _serviceId = serviceNameToIndex[_serviceName];
  if((_serviceId < service.length) && (keccak256(service[_serviceId].serviceName) == keccak256(_serviceName)))
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

modifier serviceDoesntExistsOrInactive(bytes32 _serviceName){
  uint _serviceId = serviceNameToIndex[_serviceName];
  if(serviceExists(_serviceName)){
    require(service[_serviceId].serviceStatus == accountStatus.inactive);
  }
  _;
}


modifier serviceExistsAndActive(bytes32 _serviceName){
uint32 _serviceId = serviceNameToIndex[_serviceName];
require(_serviceId < service.length);
require(keccak256(service[_serviceId].serviceName) == keccak256(_serviceName));
require(service[_serviceId].serviceStatus == accountStatus.active);
_;
}

modifier companyExistsAndActive(bytes32 _companyName){
  uint _companyId = companyAddressToIndex[msg.sender];
  require(_companyId < company.length);
  require(company[_companyId].companyName == _companyName);
  require(company[_companyId].companyStatus == accountStatus.active);
  _;
}


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

function loadMoneyAsSubscriber() subscriberExistsAndActive public payable{
  uint _subId = subscriberAddressToIndex[msg.sender]; 
  subscriber[_subId].balances += msg.value;
}

//Load money as a subscriber()  //subscriber exists  & is active (modifiers)
function ViewBalances() subscriberExistsAndActive view public returns (uint _subscriberBalance) {
  uint _subId = subscriberAddressToIndex[msg.sender]; 
  return subscriber[_subId].balances;
}

function checkIfSubscriptionExists(bytes32 _serviceName) view private
  returns (bool _serviceExists, uint32 _subscriptionArrayIndex){
uint32[] storage _existingSubscriptionIds = subscriberAddressToSubscriptionIndices[msg.sender];
//length > 0 already part of for loop
for(uint32 _index=0; _index < _existingSubscriptionIds.length; _index++)
  {
    if( (keccak256(subscriptions[_existingSubscriptionIds[_index]].serviceName) == 
    keccak256(_serviceName)) && 
    (keccak256(subscriptions[_existingSubscriptionIds[_index]].userName) == 
     keccak256(subscriber[subscriberAddressToIndex[msg.sender]].userName)))
    {
        return(true, _existingSubscriptionIds[_index]);
    } 
  }
return(false, 0);
}

//Subscribe for services - notify company (event) - SubscribeToAServiceFromACompany()
function subscribeForServices(bytes32 _serviceName) subscriberExistsAndActive
   serviceExistsAndActive(_serviceName) public returns (bool){
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
    subscriber[subscriberAddressToIndex[msg.sender]].userName);
    subscriptions.push(_newSubscription);
   }
return true;
}

function cancelSubscriptionForService(bytes32 _serviceName) subscriberExistsAndActive
   serviceExistsAndActive(_serviceName) public returns (bool){
    bool _subExists;
     uint32 _subIndex;
    (_subExists,_subIndex) = checkIfSubscriptionExists(_serviceName);
      require(_subExists);
      subscriptions[_subIndex].subscriptionStatus = accountStatus.inactive;
      subscriptions[_subIndex].subscriberSince = now;
    
}
//Cancel subscription for service() - notify company (event) 
//Withdraw Money() - //subscriber exists  & is active (modifiers) & has money in the account
//Deregister as a subscriber() // subscriber exists  & is active (modifiers)

 function withdrawMoney(uint amt) subscriberExistsAndActive public returns (bool) {
   uint _subId = subscriberAddressToIndex[msg.sender]; 
   require(subscriber[_subId].balances >= amt);
   subscriber[_subId].balances -= amt;
   msg.sender.transfer(amt);
   return true;
 }

 function deregisterAsSubscriber() subscriberExistsAndActive public{
      uint _subId = subscriberAddressToIndex[msg.sender]; 
    uint32[] storage _subscriptionIndices = subscriberAddressToSubscriptionIndices[msg.sender];
    for(uint32 _index=0; _index<_subscriptionIndices .length; _index++)
    {
    cancelSubscriptionForService(subscriptions[_subscriptionIndices[_index]].serviceName);
    }
     withdrawMoney(subscriber[_subId].balances);
 }

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

function deactiveSubscriptionsForService(bytes32 _serviceName) private {
 for(uint32 _subscriptionIndex=0; _subscriptionIndex<subscriptions.length; _subscriptionIndex++)
      {
        if(keccak256(subscriptions[_subscriptionIndex].serviceName)==(keccak256(_serviceName))){
          subscriptions[_subscriptionIndex].subscriptionStatus=accountStatus.inactive;
        }
      }
}

function deactivateService(bytes32 _serviceName) private {
      uint32 _serviceIndex = serviceNameToIndex[_serviceName];
      service[_serviceIndex].serviceStatus=accountStatus.inactive;
      deactiveSubscriptionsForService(service[_serviceIndex].serviceName);
}

function deregisterAsCompany() companyExistsAndActive(company[companyAddressToIndex[msg.sender]].companyName) public{
    uint32[] storage _servicesIndices = companyAddressToServiceIndices[msg.sender];
    for(uint32 _index=0; _index<_servicesIndices.length; _index++)
    {
      deactivateService(service[_servicesIndices[_index]].serviceName);
    }  
 }

 function deregisterServiceAsCompany(bytes32 _serviceName) serviceExistsAndActive(_serviceName) 
    companyExistsAndActive(company[companyAddressToIndex[msg.sender]].companyName) 
        public returns (bool){
    uint32[] storage _serviceIndices = companyAddressToServiceIndices[msg.sender];
    for(uint32 _index; _index<_serviceIndices.length; _index++){
      if( keccak256(service[_serviceIndices[_index]].serviceName) == keccak256(_serviceName) ){
        deactivateService(service[_serviceIndices[_index]].serviceName);
        return true;
      } 
    }
    return false;
 }


function registerServiceAsCompany(bytes32 _serviceName, uint16 _cost) 
    public serviceDoesntExistsOrInactive(_serviceName) returns (bool){
    if(serviceExists(_serviceName))
    {
      service[serviceNameToIndex[_serviceName]].serviceStatus = accountStatus.active;
    } else {
    Service memory _newService;
    _newService = Service(_serviceName, _cost, company[companyAddressToIndex[msg.sender]].companyName, accountStatus.active);
    uint32 _serviceId = uint32(service.push(_newService));
    uint32[] storage _serviceIndices = companyAddressToServiceIndices[msg.sender];
   _serviceIndices.push(_serviceId);
   }
  return true;
}


}

