import { Component, OnInit } from '@angular/core';
import { BaseChartDirective } from 'ng2-charts';
import { Categories } from '../models/Incidents';
import { Chart, ChartOptions, Colors, Legend, LineElement } from 'chart.js';
import { ApiService } from '../services/api-service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-statistics',
  imports: [CommonModule,
    FormsModule,TranslateModule, BaseChartDirective],
  templateUrl: './statistics.html',
  styleUrl: './statistics.css',
})
export class Statistics implements OnInit {


  Done: number = 0;
  AverageInChargeTime: number = 0;
  InChargeUnit: string = '';
  AverageResolutionTime: number = 0;
  ResolutionUnit: string = '';
  AverageAssignmentTime: number = 0;
  AssignmentUnit: string = '';
  selectedPeriod: string = 'week';
  selectedCategory: number | null = null;

  constructor(private apiService: ApiService, private translate: TranslateService) { }


  async ngOnInit(): Promise<void> {

    await this.loadAllStats();
    await this.loadCharts();
  }

  async changeCategory() {
  await this.loadAllStats();
  
}

async loadAllStats(): Promise<void> {
  const [
    done,
    resolution,
    charge,
    assign
  ] = await Promise.all([
    this.apiService.GetIncidentsDoneCount(this.selectedCategory),
    this.apiService.GetResolutionAverageTime(this.selectedCategory),
    this.apiService.GetInChargeAverageTime(this.selectedCategory),
    this.apiService.GetAssignementTimeAverage(this.selectedCategory)
  ]);

  this.Done = done;
  this.AverageResolutionTime = resolution.value;
  this.ResolutionUnit = resolution.unit;
  this.AverageInChargeTime = charge.value;
  this.InChargeUnit = charge.unit;
  this.AverageAssignmentTime = assign.value;
  this.AssignmentUnit = assign.unit;
}

  async changePeriod(period: string) {
    console.log("Clicked:", period);
    this.selectedPeriod = period;
    await this.loadCharts();
  }

  async loadCharts(): Promise<void> {

    const [barData, lineData] = await Promise.all([
      this.apiService.GetIncidentsByCategory(this.selectedPeriod),
      this.apiService.GetIncidentsEvolution(this.selectedPeriod)
    ]);

    this.updateBarChart(barData);
    this.updateLineChart(lineData);
  }

  updateBarChart(data: any[]) {

  this.barChartData = {
    labels: data.map(x => this.categoryLabels[x.category]),
    datasets: [
      {
        ...this.barChartData.datasets[0],
        data: data.map(x => x.count)
      }
    ]
  };

}

  updateLineChart(data: any[]) {

    this.lineChartData = {
      labels: data.map(x => x.label),
      datasets: [
        {
          ...this.lineChartData.datasets[0],
          data: data.map(x => x.count)
        }
      ]
    };

  }

  categoryLabels = Object
    .keys(Categories)
    .filter(key => isNaN(Number(key)));
  barChartData = {
    labels: [this.categoryLabels[0], this.categoryLabels[1], this.categoryLabels[2], this.categoryLabels[3], this.categoryLabels[4], this.categoryLabels[5]],
    datasets: [
      {
        label: 'Problèmes signalés',
        data: [12, 19, 3, 7, 2, 3],
        backgroundColor: [
          '#3b86a9', '#4FA37A'],
      },
    ],
  };

  barChartOptions: ChartOptions<'bar'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
  legend: {
    display: false
  }
},
    scales: {
      x: {
        border: {
          display: false   // 👈 enlève la ligne verticale à droite
        },
        ticks: {
          color: 'rgba(0,0,0,0.6)'
        },

        grid: {
          color: 'rgba(0,0,0,0.08)'
        }
      },
      y: {
        beginAtZero: true,
        suggestedMax: 10,   // ou valeur logique pour toi
        ticks: {
          stepSize: 1,
          precision: 0,
          color: 'rgba(0,0,0,0.6)'   // 👈 Labels du bas en noir
        },
        title: {
          display: false,
          text: 'Problèmes signalés',
          color: '#000000' // 👈 force title color
        },
        grid: {
          offset: false,
          color: 'rgba(0,0,0,0.08)', // 👈 force grid line color
        }
      },
    },
  };

  lineChartData = {
    labels: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
    datasets: [
      {
        label: 'Problèmes par jour ',
        data: [12, 19, 3, 7, 2, 3, 7],
        backgroundColor: '#000000',
      },
    ],
  };

  lineChartOptions: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
     plugins: {
  legend: {
    display: false
  },
},
    scales: {
      x: {
        border: {
          display: false   // 👈 enlève la ligne verticale à droite
        },
        ticks: {
         color: 'rgba(0,0,0,0.6)'
        },

        grid: {
          color: 'rgba(0,0,0,0.08)', // 👈 force grid line color
        }
      },
      y: {
        ticks: {
          color: 'rgba(0,0,0,0.6)'   // 👈 Labels du bas en noir
        },
        title: {
          display: false,
          text: 'Problèmes signalés',
          color: '#000000' // 👈 force title color
        },
        grid: {
          offset: false,
          color: 'rgba(0,0,0,0.08)', // 👈 force grid line color
        }
      },
    },
  };
}
