/**
 *  Politecnico di Milano
 *	Internet of Things Project 2021-2022
 *  @author Valeria Maria Fortina
 *	Personal code: 10537962
 */

generic configuration FakeSensorC() 
{
	provides interface Read<sensor_msg_t>;
} 

implementation 
{
	/****** COMPONENTS *****/
	components MainC, RandomC;
	components new FakeSensorP();
	
	//Connects the provided interface
	Read = FakeSensorP;
	
	/****** Wire the other interfaces down here *****/
	//Random interface and its initialization	
	FakeSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;

}
