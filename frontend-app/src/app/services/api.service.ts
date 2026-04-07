import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ApiService {

  private API_URL = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getHello() {
    return this.http.get(`${this.API_URL}/hello`, { responseType: 'text' });
  }
}