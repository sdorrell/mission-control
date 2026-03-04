#!/bin/bash

echo "Installing Project Radar..."

cd /opt/mission-control

cat > mc/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>

<title>Mission Control</title>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="/socket.io/socket.io.js"></script>

<link rel="stylesheet" href="styles.css">

</head>

<body>

<h1>🚀 Mission Control</h1>

<div class="grid">

<div class="panel">
<h2>CPU</h2>
<canvas id="cpuChart"></canvas>
</div>

<div class="panel">
<h2>Memory</h2>
<div id="memory"></div>
</div>

<div class="panel">
<h2>Projects Radar</h2>
<div id="projects"></div>
</div>

<div class="panel">
<h2>Events</h2>
<div id="events"></div>
</div>

</div>

<script src="app.js"></script>

</body>
</html>
HTML


cat > mc/app.js << 'JS'
const socket = io()

const ctx = document.getElementById("cpuChart")

let cpuData=[]

const chart=new Chart(ctx,{
 type:"line",
 data:{
  labels:[],
  datasets:[{
   label:"CPU %",
   data:cpuData
  }]
 },
 options:{animation:false}
})

socket.on("telemetry",data=>{

 document.getElementById("memory").innerText =
  data.memUsed+"GB / "+data.memTotal+"GB"

 chart.data.labels.push("")
 chart.data.datasets[0].data.push(data.cpu)

 if(chart.data.labels.length>30){
  chart.data.labels.shift()
  chart.data.datasets[0].data.shift()
 }

 chart.update()

})

async function load(){

 const projects = await fetch("/api/projects").then(r=>r.json())
 const events = await fetch("/api/events").then(r=>r.json())

 document.getElementById("projects").innerHTML =
  projects.map(p => {

   let color="gray"

   if(p.status=="active") color="green"
   if(p.status=="building") color="orange"
   if(p.status=="blocked") color="red"

   return 
   <div style="border-left:5px solid ${color};padding:8px;margin-bottom:6px">
   <strong>${p.name}</strong><br>
   Status: ${p.status}<br>
   Owner: ${p.owner}<br>
   Progress: ${p.progress}%
   </div>
   

  }).join("")

 document.getElementById("events").innerHTML =
  events.map(e=>"<div>"+e.message+"</div>").join("")

}

load()
setInterval(load,5000)
JS


pm2 restart mission-control

echo "Project Radar installed"
