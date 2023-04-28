/**
 *  Politecnico di Milano
 *	Internet of Things Project 2021-2022
 *  @author Valeria Maria Fortina
 *	Personal code: 10537962
 */


#include "Timer.h"
#include "SmartBracelet.h"
#include <stdio.h>

module SmartBraceletC @safe() {
	uses {
  
		/****** INTERFACES *****/
		interface Boot;
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
		//timers
		interface Timer<TMilli> as TimerPairing;
		interface Timer<TMilli> as Timer10s;
		interface Timer<TMilli> as Timer60s;
		//interface used to perform sensor reading
		interface Read<sensor_msg_t> as FakeSensor;
	  
  	}
}

implementation {
  
  	// Keep track of each step
	uint8_t step[] = {1,1,1};
	
	
	message_t packet;
	am_addr_t address_coupled_device;
	sensor_msg_t status;
	sensor_msg_t last_status;
	  
	bool locked = FALSE;
  
  
	void send_confirmation();
	void send_info_message();
  
  
  
	//***************** Program start ********************//
	event void Boot.booted() {
	call AMControl.start();
	}

	
	//***************** AMControl interface ********************//
	// RADIO is ready
	event void AMControl.startDone(error_t err) {
		if (err!=SUCCESS) {
			//try again
			call AMControl.start();	  		
		} 
		else {
			dbg("Radio", "ATTENTION: Radio device is ready\n");
	  		dbg("Pairing", "***PAIRING Phase has started***\n\n");
	  		call TimerPairing.startPeriodic(250); //pairing phase
		}
	}
  
  	//***************** AMControl interface ********************//
	event void AMControl.stopDone(error_t err) {}
  
 	//***************** TimerPairing interface ********************//
	event void TimerPairing.fired() {
		dbg_clear("Info","\t**************************PAIRING*********************************\n");
		dbg("TimerPairing", "ATTENTION: TimerPairing is fired at TIME: %s\n", sim_time_string());
		
		if (!locked) {
	  		brc_msg_t* sb_pairing_message = (brc_msg_t*)call Packet.getPayload(&packet, sizeof(brc_msg_t));
	  		// pairing phase
	  		sb_pairing_message->msg_type = PAIR; 
	  		memcpy(sb_pairing_message->data, KEY[TOS_NODE_ID/2],20);
		    
	  		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(brc_msg_t)) == SUCCESS) {
	  			locked = TRUE;
		  		dbg("Radio", "Preload KEY=%s , SENDING PAIRING MESSAGE \n\n", KEY[TOS_NODE_ID/2]);	
	  		}
		}
	}
  
  	//***************** Timer60s interface ********************//
	event void Timer60s.fired() {  // Timer60s fired
		dbg("Timer60s", "Timer of 60s is FIRED at TIME: %s\n\n", sim_time_string());
		dbg_clear("Info", "\t\tM I S S I N G   A L E R T\n");
		dbg("Info", "TIMEOUT\n");
		dbg("Info", "ATTENTION PLEASE This is a MISSING  ALERT!\n");
		dbg("Info", "LAST KNOWN POSITION OF THE CHILD  X: %hhu, Y: %hhu\n", last_status.X, last_status.Y);
		dbg_clear("Info", "\t\tM I S S I N G   A L E R T\n\n");

	}

  	//***************** Timer10s interface ********************//
	event void Timer10s.fired() { // Timer10s fired
		dbg("Timer10s", "Timer of 10s is FIRED at TIME %s\n", sim_time_string());
		call FakeSensor.read();
	}

	//***************** AMSend interface ********************//
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&packet == bufPtr && error == SUCCESS) {
			uint8_t phase = step[TOS_NODE_ID];
	  		brc_msg_t* message = (brc_msg_t*)call Packet.getPayload(&packet, sizeof(brc_msg_t));
	  		dbg("Radio_sent", "Message sent!\n");
	  		locked = FALSE;
	  
	  		if (message->msg_type == PAIR){
	   			dbg("Pairing","Random key recepted by other bracelets\n\n");
	  		}
	  		else if(phase == CONFIRM && call PacketAcknowledgements.wasAcked(bufPtr) ){
				// PHASE == 1 and ack received
				call TimerPairing.stop();
				dbg("Radio_ack", "Pairing ACK received at time %s\n\n", sim_time_string());
		
				// Phase 1 done
				step[TOS_NODE_ID] = EXCHANGE; 
		
				// Check if parent or child
				if (TOS_NODE_ID % 2 == 0){
		  			// is Parent bracelet 60 s
		  			dbg("OperationalMode","It's Parent bracelet\n\n");
		  			call Timer60s.startOneShot(60000);
		  		} 
		  		else {
		  		// is Child bracelet 10 s
		 		dbg("OperationalMode","It's Child bracelet\n\n");
		  		call Timer10s.startPeriodic(10000);
				}
	  		}
	  		
	  		else if (call PacketAcknowledgements.wasAcked(bufPtr) && phase == EXCHANGE){
				// Ack received in phase 2
				dbg("Radio_ack", "COMPLETE: ACK received at time %s\n\n", sim_time_string());
			} 
	  		else if (phase == EXCHANGE){
				// Ack not received in phase 2
				dbgerror("Radio_ack", "ATTENTION: ACK EXCHANGE phase not received, try again\n\n");
				send_info_message();
	  		}
	  		else if (phase == CONFIRM){ // Ack not received in phase 1
				dbgerror("Radio_ack", "ATTENTION: ACK CONFIRMATION phase not received, try again\n\n");
				// Send confirmation again
				send_confirmation(); 
	  		}
		}
	}
  
  //***************** Receive interface ********************//
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		brc_msg_t* mess = (brc_msg_t*)payload;

		// Received packet
	  	dbg("Radio_rec","TIME %s : a message is received from Mote %hhu\n", sim_time_string(), call AMPacket.source(bufPtr));
	  	dbg_clear("Info","\t**************************MESSAGE*********************************\n");
	  	dbg_clear("Radio_pack","\t\tPayload: type: %hu, info: %s\n", mess->msg_type, mess->data);


		//if pairing from wrong device
	 	if(call AMPacket.destination( bufPtr ) == AM_BROADCAST_ADDR && !memcmp(mess->data, KEY[TOS_NODE_ID/2],20)==0){
	  		dbg_clear("Radio_pack","\t\tMessage for PAIRING request received. Mote address: %hhu\n", call AMPacket.source( bufPtr ));
	  		dbgerror_clear("Radio_pack","\t\t !! WRONG BRACELET !! \n\n");
	  		
		}

		//if is pairing device
		else if (call AMPacket.destination(bufPtr) == AM_BROADCAST_ADDR && memcmp(mess->data, KEY[TOS_NODE_ID/2],20)==0){
		  	address_coupled_device = call AMPacket.source(bufPtr);
		  	//confirmation of pairing 
		  	dbg_clear("Radio_pack","\t\tMessage of PAIRING request received. Mote address: %hhu\n", address_coupled_device);
		  	dbg_clear("Info","\t\t%s\n","BRACELET FOUND!\n");	
		  	step[TOS_NODE_ID] = CONFIRM;
		  	send_confirmation(); 
		}
		
		// Kinematic message
		else if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID && mess->msg_type == EXCHANGE) {
	  		dbg_clear("Radio_pack","\t\t%s\n","Kinematic message received");
	  		dbg_clear("Info", "\t\tSensor kinematic status: %s\n", mess->data);
	  		dbg_clear("Info", "\t\tChild Position X: %hu, Y: %hu\n\n", mess->X, mess->Y);	
	  		last_status.X = mess->X;
	  		last_status.Y = mess->Y;
	  
	  		// FALLING ALLERT
	  		if (strcmp(mess->data,"FALLING") == 0){
				dbg_clear("Info", "\n");
				dbg_clear("Info", "\t\tF A L L I N G   A L E R T\n");
				dbg("Info", "ATTENTION PLEASE This is a FALLING  ALERT!\n");
				dbg("Info", "THE CHILD HAS FALLEN!\n");
				dbg_clear("Info", "\t\tF A L L I N G   A L E R T\n\n");
			
	  		}
	  		call Timer60s.startOneShot(60000);
		}

		//if received CONFIRMATION message
		else if (call AMPacket.destination( bufPtr ) == TOS_NODE_ID && mess->msg_type == CONFIRM) {
	  		dbg_clear("Radio_pack","\t\t%s\n","Message for CONFIRMATION received\n\n");
	  		call TimerPairing.stop();
	  		step[TOS_NODE_ID] = EXCHANGE; 
	  		//check if parent or child
			if (TOS_NODE_ID % 2 == 0){
		  	// Parent bracelet
		  	dbg("OperationalMode","It's Parent bracelet\n\n");
		  	call Timer60s.startOneShot(60000);
			} 
			else {
		  	// Child bracelet
		  	dbg("OperationalMode","It's Child bracelet\n\n");
		  	call Timer10s.startPeriodic(10000);
			}
		} 

		return bufPtr;
	}

	 
	/***************** Send confirmation ********************/
	void send_confirmation(){
		if (!locked) {
		  	brc_msg_t* sb_pairing_message = (brc_msg_t*)call Packet.getPayload(&packet, sizeof(brc_msg_t));
		  
		  	// Confirmation
		  	sb_pairing_message->msg_type = CONFIRM; 
		  	memcpy(sb_pairing_message->data, KEY[TOS_NODE_ID/2],20);
		  	// ACK request
		  	call PacketAcknowledgements.requestAck( &packet );
		  
		  	if (call AMSend.send(address_coupled_device, &packet, sizeof(brc_msg_t)) == SUCCESS) {
		  		locked = TRUE;
				dbg("Radio", "Sending CONFIRMATION to mote address %hhu\n\n", address_coupled_device);	
				
		  	}
		}
	}
  
  /***************** Send info message ********************/
	void send_info_message(){
		if (!locked) {
			brc_msg_t* sb_pairing_message = (brc_msg_t*)call Packet.getPayload(&packet, sizeof(brc_msg_t));
		
			// Fill message
			sb_pairing_message->X = status.X;
			sb_pairing_message->Y = status.Y;
			sb_pairing_message->msg_type = EXCHANGE; 
			memcpy(sb_pairing_message->data, status.status,10);
		
			// ACK request
			call PacketAcknowledgements.requestAck( &packet );
		
			if (call AMSend.send(address_coupled_device, &packet, sizeof(brc_msg_t)) == SUCCESS) {
				locked = TRUE;
			  	dbg("Radio", "Radio: sending INFO packet to mote %hhu \n\n", address_coupled_device);	
			  }
	  }
	}
	
	//***************** FakeSensor interface ********************//
	event void FakeSensor.readDone(error_t result, sensor_msg_t status_local) {
		dbg_clear("Info","\t**************************MESSAGE*********************************\n");
		status = status_local;
		dbg_clear("Sensors", "\t\tSensor kinematic status: %s\n", status.status);
		dbg_clear("Sensors", "\t\tChild Position X: %hhu, Y: %hhu\n\n", status_local.X, status_local.Y);
		send_info_message();

	}
	
}




