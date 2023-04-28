/**
 *  Politecnico di Milano
 *	Internet of Things Project 2021-2022
 *  @author Valeria Maria Fortina
 *	Personal code: 10537962
 */


#include "SmartBracelet.h"

configuration SmartBraceletAppC {}

implementation {

  components MainC, SmartBraceletC as App;
  
  //radio
  components new AMSenderC(AM_RADIO_TYPE);
  components new AMReceiverC(AM_RADIO_TYPE);
  components ActiveMessageC as RadioAM;
  
  //Timers
  components new TimerMilliC() as TimerPairing;
  components new TimerMilliC() as Timer10s;
  components new TimerMilliC() as Timer60s;
  
  //for kinematic
  components new FakeSensorC();
  
  // Boot interface
  App.Boot -> MainC.Boot;
  
  // Radio interface
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.AMControl -> RadioAM;
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.PacketAcknowledgements -> RadioAM;
  
  App.FakeSensor -> FakeSensorC;

  // Timers
  App.TimerPairing -> TimerPairing;
  App.Timer10s -> Timer10s;
  App.Timer60s -> Timer60s;
  

 
}


