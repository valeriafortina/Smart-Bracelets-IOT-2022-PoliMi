/**
 *  Politecnico di Milano
 *	Internet of Things Project 2021-2022
 *  @author Valeria Maria Fortina
 *	Personal code: 10537962
 */

#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

//steps
#define PAIR 0
#define CONFIRM 1
#define EXCHANGE 2


// Message struct
typedef nx_struct brc_msg {
  	nx_uint8_t msg_type;
  	nx_uint8_t data[20];
  	nx_uint8_t X;
  	nx_uint8_t Y;
} brc_msg_t;


//sensor message position & kinematic
typedef struct sensor_msg {
  uint8_t status[10];
  uint8_t X;
  uint8_t Y;
}sensor_msg_t;


//Random pre-loaded key list 
static const char *KEY[]={
    "HDSGAhdyqgi76h7dedgh",
    "BYTg6td7beggd67sa67v",
    "nhyufdgwf7487hfeuSRC",
    "hfyewugfqyg565FRDEdr",
    "56ftDTDGff66bTYTF6TY",
    "DNHUEWG6GYF56t67gyug",
    "hdueigyyhgs5tffhvght",
    "FRD6gygyhFDhh67gtygf",
};


// Constants
enum {
  AM_RADIO_TYPE = 6,
};


#endif
