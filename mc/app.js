const socket = io()

const cpuCanvas = document.getElementById("cpuChart")

let cpuData = []

const chart = new Chart(cpuCanvas, {
 type: "line",
 data: {
  labels: [],
  datasets: [{
   label: "CPU %",
   data: cpuData,
   borderColor: "#00e5ff",
   tension: 0.2
  }]
 },
 options: {
  animation: false,
  scales: {
   y: {
    min: 0,
    max: 100
   }
  }
 }
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
