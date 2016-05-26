import ddf.minim.*;
import controlP5.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.ugens.*;
import ddf.minim.*;
import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;
import java.util.*;
import java.net.InetAddress;
import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;

import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.action.admin.cluster.health.ClusterHealthResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;


static String INDEX_NAME = "canciones";
static String DOC_TYPE = "cancion";


//comienza la locura
FFT fftLin;
FFT fftLog;
float height3;
float height23;
float spectrumScale = 4;
HighPassSP highpass;
LowPassSP lowpass;
BandPass bandpass;
LowPassFS   lpf;
//termina la locura 
int Hpass;
int Lpass;
int Bpass;


ControlP5 cp5;
ScrollableList list;

Client client;
Node node;
String lista;
float aux2= 50;
ControlP5 play, detener, pause, sl, cargar;
Minim minim;
String Autor="", Titulo="";

AudioPlayer musica;
AudioOutput output;
AudioMetaData meta;

boolean car=true;
float Volumen, aux;



void setup() {
  size(700, 500);
  //masgkoasjgañs
  height3 = height/3;
  height23 = 2*height/3;

  //kldgañslkghajñglas
  
  
//fileSelector = new JFileChooser();
cp5 = new ControlP5(this);

  // Configuracion basica para ElasticSearch en local
  Settings.Builder settings = Settings.settingsBuilder();
  // Esta carpeta se encontrara dentro de la carpeta del Processing
  settings.put("path.data", "esdata");
  settings.put("path.home", "/");
  settings.put("http.enabled", false);
  settings.put("index.number_of_replicas", 0);
  settings.put("index.number_of_shards", 1);

  // Inicializacion del nodo de ElasticSearch
  node = NodeBuilder.nodeBuilder()
          .settings(settings)
          .clusterName("mycluster")
          .data(true)
          .local(true)
          .node();

  // Instancia de cliente de conexion al nodo de ElasticSearch
  client = node.client();

  // Esperamos a que el nodo este correctamente inicializado
  ClusterHealthResponse r = client.admin().cluster().prepareHealth().setWaitForGreenStatus().get();
  println(r);

  // Revisamos que nuestro indice (base de datos) exista
  IndicesExistsResponse ier = client.admin().indices().prepareExists(INDEX_NAME).get();
  if(!ier.isExists()) {
    // En caso contrario, se crea el indice
    client.admin().indices().prepareCreate(INDEX_NAME).get();
  }

  // Agregamos a la vista un boton de importacion de archivos
  cp5.addButton("importFiles")
    .setPosition(500, 10)
    .setLabel("Cargar");

  // Agregamos a la vista una lista scrollable que mostrara las canciones
  list = cp5.addScrollableList("playlist")
            .setPosition(500, 40)
            .setSize(200, 300)
            .setBarHeight(20)
            
            .setItemHeight(20)
            .setType(ScrollableList.LIST);

  // Cargamos los archivos de la base de datos
  loadFiles();
  play = new ControlP5(this);
  play.addButton("play")
    .setValue(0)
    .setPosition(500,300)
    .setSize(40, 40);
  aux= Volumen;
  pause = new ControlP5(this);
  pause.addButton("pause")
    .setValue(0)
    .setPosition(550, 300)
    .setSize(40, 40);

  detener = new ControlP5(this);
  detener.addButton("detener")
    .setValue(0)
    .setPosition(600, 300)
    .setSize(40, 40);

  sl= new ControlP5(this);
  sl.addSlider("Volumen")
    .setValue(50)
    .setPosition(500, 355)
    .setSize(120, 30);
    
  sl.addKnob("Hpass")
  .setValue(0)
  .setPosition(500, 430)
  .setRange(0,3000)
  .setValue(0)
  .setSize(50, 50);
  
   sl.addKnob("Lpass")
  .setValue(0)
  .setPosition(570, 430)
  .setRange(3000,5000)
  .setValue(3000)
  .setSize(50, 50);
  
   sl.addKnob("Bpass")
  .setValue(0)
  .setPosition(640, 430)
  .setRange(100,1000)
  .setValue(100)
  .setSize(50, 50);
    
  minim = new Minim(this);
  

 /* cargar= new ControlP5(this);
  cargar.addButton("Cargar")
    .setPosition(200, 50)
    .setSize(40, 40);*/
}
void draw() {
  background(0);
  //fill(200);
  //rect(10,10,280,350);
  if(Titulo != ""){
  fill(255);
  textSize(15);
  text("Titulo: "+Titulo,100,22);
  text("Autor: "+Autor,100,45);}
  barras();
  if(musica!=null){
   highpass.setFreq(Hpass);
    lowpass.setFreq(Lpass);
    bandpass.setFreq(Bpass); 
  }
 
}
public void play() {
  
  musica.play();
  meta= musica.getMetaData();
  Titulo = meta.title();
  Autor = meta.author();
  println(Volumen);
}

public void controlEvent(ControlEvent event) {
  println(event.getController().getName());
}

public void dd() {
  musica.pause();
  musica.rewind();
}

public void detener() {
  dd();
}

public void pause() {
  musica.pause();
}


public void Volumen(float volumen) {
  float Volumen=volumen;
  musica.setGain(0);
  if (Volumen>50) {
    musica.setGain(musica.getGain()+(Volumen));
    aux2=50;
  } else {
    aux2= aux2-volumen;
    musica.setGain(-aux2);
    aux2=50;
  }
 /* if (volumen == 0){
   musica.mute(); 
  }else {
   musica.setMute(); 
  }*/
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    minim = new Minim(this);
   highpass = new HighPassSP(300, musica.sampleRate());
   musica.addEffect(highpass);
   lowpass = new LowPassSP(300, musica.sampleRate());
   musica.addEffect(lowpass);
   bandpass = new BandPass(300, 300, musica.sampleRate());
   musica.addEffect(bandpass);
    //musica = minim.loadFile((String)value.get("path"), 1024);
  }
}
/*public void Cargar() {
 selectInput("Selecciona la cancion:", "fileSelected");
 dd();
}*/