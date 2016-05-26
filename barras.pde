void barras(){

  
  if(musica!=null){
    float centerFrequency = 0;
  fftLin.forward( musica.mix );
  fftLog.forward( musica.mix );
  {
    noFill();
    
}
  
  noStroke();
  
  {
    int w = int( width/fftLin.avgSize() );
    for(int i = 0; i < fftLin.avgSize()-4; i++)
    {
      {
          fill(128);
      }
      fill(0,int(fftLin.getAvg(i)*5*spectrumScale),int(fftLin.getAvg(i)*10*spectrumScale));
      if (i==0){
      rect(i*w, height, i*w + w, height - int(fftLin.getAvg(i)*15*spectrumScale));//these things draw the wrong way up...
      }else{rect(i*w, height, i*w + w, height - int(fftLin.getAvg(i)*20*spectrumScale));}
      stroke(255);
      if (i>7){rect(10,10,10,10);}
      line(i*w, height, i*w, height - 10) ;
      noStroke();
     
    }
  }
  }
}