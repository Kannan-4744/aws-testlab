import { Component, OnInit } from '@angular/core';
import { ApiService } from './services/api.service';

@Component({
  selector: 'app-root',
  template: `<h1>{{message}}</h1>`
})
export class AppComponent implements OnInit {

  message = 'Loading...';

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.api.getHello().subscribe({
      next: (res) => {
        this.message = res;
      },
      error: (err) => {
        console.error(err);
        this.message = 'Error connecting backend';
      }
    });
  }
}