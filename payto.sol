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
  bytes32 companyName;
  address companyAddress;
  accountStatus companyStatus;
  }

 Company[] company;
 mapping (bytes32 => uint[]) companyToServiceIndex;
 mapping (bytes32 => uint) companyNameToIndex;

  //start Services data structure
mapping (bytes32 => uint) serviceNameToIndex;
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
   Subscription[] subscription; 
   accountStatus subscriberStatus;
   }

struct Subscription {
   bytes32 serviceName;
   accountStatus subscriptionstatus;
   bytes32 subscriberSince;
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

modifier subscriberExistsOrInactive(){
  uint _subId = subscriberAddressToIndex[msg.sender];
  require(_subId < subscriber.length);
  require((subscriber[_subId].subscriberAddress == msg.sender) || (subscriber[_subId].subscriberStatus == accountStatus.active));
  _;
}

modifier servicesExistsAndActive(bytes32 _serviceName){
uint _serviceId = serviceNameToIndex[_serviceName];
require(_serviceId < service.length);
require(keccak256(service[_serviceId].serviceName) == keccak256(_serviceName));
require(service[_serviceId].serviceStatus == accountStatus.active);
_;
}

modifier companyExistsAndActive(bytes32 _companyName){
  uint _companyId = companyNameToIndex[_companyName];
  require(_companyId < company.length);
  require(company[_companyId].companyName == _companyName);
  require(company[_companyId].companyStatus == accountStatus.active);
  _;
}


function registerAsSubscriber(bytes32 _userName) subscriberExistsOrInactive {
 Subscription[] _newSub;
 Subscriber newSubscriber =  Subscriber(msg.sender, _userName, 0, _newSub, accountStatus.active);
 uint _newSubscriberId = subscriber.push(newSubscriber);
 subscriberAddressToIndex[msg.sender] = _newSubscriberId;

} //- [send money initially] // subscriber doesn’t exists  or is in active (modifiers)

function loadMoneyAsSubscriber() subscriberExistsAndActive payable{
  uint _subId = subscriberAddressToIndex[msg.sender]; 
  subscriber[_subId].balances =+ msg.value;
}

//Load money as a subscriber()  //subscriber exists  & is active (modifiers)
function ViewBalances() subscriberExistsAndActive returns (uint _subscriberBalance) {
  uint _subId = subscriberAddressToIndex[msg.sender]; 
  subscriber[_subId].balances;
}

function checkIfSubscriptionExists(bytes32 _serviceName) view 
  returns (bool _serviceExists, uint32 _serviceIndexInSub){
Subscription[] _existingSubscriptions = subscriberAddressToIndex[msg.sender].subscription;

for(uint _index=0; _index < _existingSubscriptions.length; _index++)
  {
    if( keccak256(_existingSubscriptions[_index].serviceName) == keccak256(_serviceName) )
    {
        return(true, _index);
    } 
  }
return(false, 0);
}

//Subscribe for services - notify company (event) - SubscribeToAServiceFromACompany()
function subscribeForServices(bytes32 _serviceName) subscriberExistsAndActive
   servicesExistsAndActive(_serviceName) returns (bool){
Subscription _newSubscription = new Subscription(_serviceName, accountStatus.active, now());
subscriber[subscriberAddressToIndex[msg.sender]].subscription.push(_newSubscription);
return true;
}

function cancelSubscriptionForService(bytes32){

}
//Cancel subscription for service() - notify company (event) 
//Withdraw Money() - //subscriber exists  & is active (modifiers) & has money in the account
//Deregister as a subscriber() // subscriber exists  & is active (modifiers)



}
