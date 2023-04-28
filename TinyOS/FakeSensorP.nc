/**
 *  Politecnico di Milano
 *	Internet of Things Project 2021-2022
 *  @author Valeria Maria Fortina
 *	Personal code: 10537962
 */

#include <stdio.h>
generic module FakeSensorP() {

	provides interface Read<sensor_msg_t>;
	uses interface Random;

}

implementation 
{

	task void readDone();

	//***************** Read interface ********************//
	command error_t Read.read(){
		post readDone();
		return SUCCESS;
	}

	//******************** Read Done **********************//
	task void readDone() {
	  
	  sensor_msg_t mess;

	  int random_number = (call Random.rand16() % 10);
	  mess.X = (call Random.rand16());
	  mess.Y = (call Random.rand16());
	  
		
		if (random_number >=0 && random_number <= 2){
		  memcpy(mess.status, "STANDING",10);
		} else if (random_number <= 5){
		  memcpy(mess.status, "WALKING",10);
		} else if (random_number <= 8){
		  memcpy(mess.status, "RUNNING",10);
		} else {
		  memcpy(mess.status, "FALLING",10);
		}
	
	  
	  
	  
	  signal Read.readDone( SUCCESS, mess);
	  
	}
}  
