import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { lastValueFrom } from 'rxjs';
import { Citizen, RegisterDTO, SortedIncidentdsDTO, QueryParametersDTO, PagedResult, ConversationDto, MessageDto, CitizenDto, EvolutionChartDto, CategoryChartDto } from '../models/Incidents';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  http = inject(HttpClient);
  //private serverUrl = "http://localhost:5177";
    private serverUrl = "https://serveurmunicipaligo-c6c7hbgbhsdugjag.canadacentral-01.azurewebsites.net";

  async GetDetails(id: number): Promise<any> {
    try {
      let result = await lastValueFrom(this.http.get(this.serverUrl + `/api/Incidents/${id}`));
      console.log('Details from /api/Incidents/{id}:', result);
      return result;
    } catch (e) {
      console.error('Failed to get details:', e);
      throw e;
    }
  }
  async EditIncident(id: number, updatedData: any): Promise<void> {
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/Edit/${id}`, updatedData)
    );
    console.log(`Incident ${id} updated`);
  }
 
  // --- Commentaires ---
  async PostComment(incidentId: number, message: string, parentCommentId?: number): Promise<any> {
    const params: any = { incidentId, message };
    if (parentCommentId) params.commentId = parentCommentId;
    return await lastValueFrom(
      this.http.post<any>(`${this.serverUrl}/api/Comments/PostComment`, null, { params })
    );
  }
 
  async GetComments(incidentId: number, page = 1, pageSize = 10): Promise<any[]> {
    const params = { incidentId, page, pageSize };
    return await lastValueFrom(
      this.http.get<any[]>(`${this.serverUrl}/api/Comments/GetComments`, { params })
    );
  }
 
  async GetReplies(commentId: number, page = 1, pageSize = 10): Promise<any[]> {
    const params = { commentId, page, pageSize };
    return await lastValueFrom(
      this.http.get<any[]>(`${this.serverUrl}/api/Comments/GetReplies`, { params })
    );
  }
 
  async ToggleLikeComment(commentId: number): Promise<void> {
    await lastValueFrom(
      this.http.put<void>(`${this.serverUrl}/api/Comments/ToggleLikeComment`, null, { params: { commentId } })
    );
  }
 
  async DeleteComment(commentId: number): Promise<void> {
    await lastValueFrom(
      this.http.delete<void>(`${this.serverUrl}/api/Comments/DeleteComment`, { params: { commentId } })
    );
  }
 
  async ReportComment(commentId: number): Promise<void> {
    await lastValueFrom(
      this.http.post<void>(`${this.serverUrl}/api/Comments/ReportComment`, null, { params: { commentId } })
    );
  }
 
  async GetConfirmationDetails(id: number): Promise<any> {
    try {
      let result = await lastValueFrom(this.http.get(this.serverUrl + `/api/Incidents/DetailsConfirmation/${id}`));
      console.log('/api/Incidents/DetailsConfirmation/{id}:', result);
      return result;
    } catch (e) {
      console.error('Failed to get confirmation details:', e);
      throw e;
    }
  }
 
  async login(email: string, password: string): Promise<void> {
    const dto = { username: email, password: password };
 
    const response = await lastValueFrom(
      this.http.post<any>(this.serverUrl + '/api/User/login', dto)
    );
 
 
 
    console.log(response);
    localStorage.setItem("token", response.token);
    const token = localStorage.getItem("token");
 
    const payload = JSON.parse(atob(token!.split('.')[1]));
    const role = payload.role;
    localStorage.setItem("role", role);
  }
 
  logout(): void {
    localStorage.removeItem("token");
  }
 
  isLoggedIn(): boolean {
    const token = localStorage.getItem("token");
    return !!token;
  }
 
  async GetAllSortedIncidents(filter?: QueryParametersDTO): Promise<PagedResult<SortedIncidentdsDTO>> {
    let result = await lastValueFrom(
      this.http.post<any>(`${this.serverUrl}/api/admin/AllSortedIncidents`, filter)
    );
 
    return result;
  }
 
  async GetNotAssignedSortedIncidents(filter?: QueryParametersDTO): Promise<PagedResult<SortedIncidentdsDTO>> {
    let result = await lastValueFrom(
      this.http.post<any>(`${this.serverUrl}/api/Incidents/Not-Assigned`, filter)
    );
    console.log(result);
    return result;
  }
 
  async GetNotValidatedSortedIncidents(filter?: QueryParametersDTO): Promise<PagedResult<SortedIncidentdsDTO>> {
    let result = await lastValueFrom(
      this.http.post<any>(`${this.serverUrl}/api/Incidents/Not-Validated`, filter)
    );
    return result;
  }
 
  async GetValidatedIncidents(): Promise<any[]> {
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/Validated`)
    );
    console.log(result);
    return result;
  }
 
  async GetAssignedToCitizenIncidents(): Promise<any[]> {
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/AssignedToCitizen`)
    );
    return result;
  }
 
  async GetUnderRepairIncidents(): Promise<any[]> {
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/UnderRepair`)
    );
    return result;
  }
 
  async GetNotConfirmedIncidents(): Promise<any[]> { // Changed from Incident[] to any[]
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/Not-Confirmed`)
    );
    return result;
  }
 
  async GetDoneIncidents(): Promise<any[]> {
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/Done`)
    );
    return result;
  }
 
  async GetMyAssignedIncidents(): Promise<any[]> {
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/MyAssignedIncidents`)
    );
    return result;
  }
 
  async GetIncidentHistory(incidentId: number): Promise<any[]> {
    let result = await lastValueFrom(
      this.http.get<any[]>(this.serverUrl + `/api/Incidents/IncidentHistory/${incidentId}`)
    );
    return result;
  }

  async ApproveIncident(incidentId: number,updatedData: any): Promise<void> {
   
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/Approuve/${incidentId}`, updatedData)
    );
    console.log(`Incident ${incidentId} approved`);
  }
 
  async RefuseIncident(incidentId: number): Promise<void> {
    await lastValueFrom(
      this.http.delete<void>(this.serverUrl + `/api/Incidents/Delete/${incidentId}`)
    );
    console.log(`Incident ${incidentId} refused`);
  }
 
  async ConfirmIncident(incidentId: number): Promise<void> {
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/Confirm/${incidentId}`, {})
    );
    console.log(`Incident ${incidentId} approved`);
  }
 
  async RefuseConfirmationIncident(incidentId: number, description?: string): Promise<void> {
    const dto = { incidentId: incidentId, description: description };
 
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/Refuse`, dto)
    );
    console.log(`Incident confirmation ${incidentId} refused`);
  }
 
  async AssignIncidentToCitizen(incidentId: number): Promise<void> {
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/AssignToCitizen/${incidentId}`, {})
    );
    console.log(`Incident ${incidentId} assigned to citizen`);
  }
 
  async AssignIncidentToBlueCollar(incidentId: number): Promise<void> {
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/Assign/BlueCollar/${incidentId}`, {})
    );
    console.log(`Incident ${incidentId} assigned to blue collar`);
  }
 
  async CitizenTakeTask(incidentId: number, citizenId: number): Promise<void> {
    await lastValueFrom(
      this.http.put<void>(this.serverUrl + `/api/Incidents/Assign/take/${incidentId}?citizenId=${citizenId}`, {})
    );
    console.log(`Incident ${incidentId} taken by citizen ${citizenId}`);
  }
 
  async GetUsers(): Promise<Citizen[]> {
    let result = await lastValueFrom(
      this.http.get<Citizen[]>(this.serverUrl + `/api/Admin/User-list`)
    );
    return result;
  }
 
  async GetUserById(userId: string): Promise<Citizen | null> {
 
    let result = await lastValueFrom(
      this.http.get<Citizen>(this.serverUrl + `/api/Admin/${userId}/details`)
    );
    return result;
 
  }
 
  async UpdateUser(userId: string, updatedData: any): Promise<void> {
    await lastValueFrom(
      this.http.patch<void>(this.serverUrl + `/api/Admin/user/${userId}`, updatedData)
    );
    console.log(`User ${userId} updated`);
  }
 
  async createUser(dto: RegisterDTO): Promise<void> {
    await lastValueFrom(
      this.http.post<void>(
        `${this.serverUrl}/api/User/Register`,
        dto
      )
    );
 
    console.log('User created');
  }
 
 
  async GetLikeCount(incidentId: number): Promise<number> {
    let result = await lastValueFrom(
      this.http.get<{ likeCount: number }>(this.serverUrl + `/api/Incidents/${incidentId}/likes/count`)
    );
    return result.likeCount;
  }
 
  async ExportIncidentsToExcel(filter?: QueryParametersDTO): Promise<void> {
    const blob = await lastValueFrom(
      this.http.post(`${this.serverUrl}/api/Export/Excel`, filter, { responseType: 'blob' })
    );
 
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'incidents.xlsx';
    a.click();
    window.URL.revokeObjectURL(url);
  }

  GetChatIncidents(): Promise<any[]> {
    return lastValueFrom(
      this.http.get<any[]>(`${this.serverUrl}/api/Chat/incidents`)
    );
  }

  DeleteConversation(partnerCitizenId: number): Promise<void> {
    return lastValueFrom(
      this.http.delete<void>(`${this.serverUrl}/api/Chat/conversations/${partnerCitizenId}`)
    );
  }

 
  async ExportIncidentsToPDF(filter?: QueryParametersDTO): Promise<void> {
    const blob = await lastValueFrom(
      this.http.post(`${this.serverUrl}/api/Export/PDF`, filter, { responseType: 'blob' })
    );
 
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'incidents.pdf';
    a.click();
    window.URL.revokeObjectURL(url);
  }
 
  async ExportIncidentsToJSON(filter?: QueryParametersDTO): Promise<void> {
    const blob = await lastValueFrom(
      this.http.post(`${this.serverUrl}/api/Export/JSON`, filter, { responseType: 'blob' })
    );
 
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'incidents.json';
    a.click();
    window.URL.revokeObjectURL(url);
  }

async GetConversations(): Promise<ConversationDto[]> {
  return await lastValueFrom(
    this.http.get<ConversationDto[]>(`${this.serverUrl}/api/Chat/conversations`)
  );
}

async GetMessages(partnerCitizenId: number, page = 1, pageSize = 50): Promise<MessageDto[]> {
  return await lastValueFrom(
    this.http.get<MessageDto[]>(`${this.serverUrl}/api/Chat/messages/${partnerCitizenId}`, {
      params: { page, pageSize }
    })

  );
}

async SearchCitizens(search?: string): Promise<CitizenDto[]> {
  const params: any = {};
  if (search) params.search = search;
  return await lastValueFrom(
    this.http.get<CitizenDto[]>(`${this.serverUrl}/api/Chat/users`, { params })
  );
}

async MarkAsRead(partnerCitizenId: number): Promise<void> {
  await lastValueFrom(
    this.http.post<void>(`${this.serverUrl}/api/Chat/messages/read/${partnerCitizenId}`, null)
  );
}
  async GetResolutionAverageTime(selectedCategory?: number | null): Promise<any> {
  const url = selectedCategory != null
    ? `${this.serverUrl}/api/Stats/resolution?category=${selectedCategory}`
    : `${this.serverUrl}/api/Stats/resolution`;
 
  return await lastValueFrom(this.http.get<any>(url));
}
 
async GetInChargeAverageTime(selectedCategory?: number | null): Promise<any> {
  const url = selectedCategory != null
    ? `${this.serverUrl}/api/Stats/charge?category=${selectedCategory}`
    : `${this.serverUrl}/api/Stats/charge`;
 
  return await lastValueFrom(this.http.get<any>(url));
}
 
async GetIncidentsDoneCount(selectedCategory?: number | null): Promise<number> {
  const url = selectedCategory != null
    ? `${this.serverUrl}/api/Stats/total?category=${selectedCategory}`
    : `${this.serverUrl}/api/Stats/total`;
 
  return await lastValueFrom(this.http.get<number>(url));
}
 
async GetAssignementTimeAverage(selectedCategory?: number | null): Promise<any> {
  const url = selectedCategory != null
    ? `${this.serverUrl}/api/Stats/AssignTime?category=${selectedCategory}`
    : `${this.serverUrl}/api/Stats/AssignTime`;
 
  return await lastValueFrom(this.http.get<any>(url));
}
 
  GetIncidentsByCategory(period: string) {
  return lastValueFrom(
    this.http.get<CategoryChartDto[]>(
      `${this.serverUrl}/api/Stats/categories-chart?period=${period}`
    )
  );
}
 
GetIncidentsEvolution(period: string) {
  return lastValueFrom(
    this.http.get<EvolutionChartDto[]>(
      `${this.serverUrl}/api/Stats/evolution-chart?period=${period}`
    )
  );
}

  getToken(): string {
    return localStorage.getItem('token') ?? '';
  }

async GetTotalIncidents(): Promise<number> {
  return await lastValueFrom(
    this.http.get<number>(this.serverUrl + `/api/Stats/total`)
  );
}


}