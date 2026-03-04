const socket = io()

const cpuCanvas = document.getElementById("cpuChart")

let cpuData = []

const chart = new Chart(cpuCanvas, {
 type: "line",
 data: {
  labels: [],
  datasets: [{
   label: "CPU %",
   data: cpuData
  }]
 },
 options: { animation: false }
})

socket.on("telemetry", data => {

 document.getElementById("memory").innerText =
  data.memUsed + "GB / " + data.memTotal + "GB"

 chart.data.labels.push("")
 chart.data.datasets[0].data.push(data.cpu)

 if (chart.data.labels.length > 30) {
  chart.data.labels.shift()
  chart.data.datasets[0].data.shift()
 }

 chart.update()

})

async function load() {

 const projects = await fetch("/api/projects").then(r => r.json())
 const events = await fetch("/api/events").then(r => r.json())

document.getElementById("projects").innerHTML =
  projects.map(p =>
   `<div><strong>${p.name}</strong><br>Status: ${p.status}<br>Progress: ${p.progress}%</div>`
  ).join("")

document.getElementById("events").innerHTML =
  events.map(e =>
   `<div>${e.message}</div>`
  ).join("")
}

load()
setInterval(load, 5000)
